const std = @import("std");

// Python C API bindings
const c = @cImport({
    @cInclude("Python.h");
    @cInclude("numpy/arrayobject.h");
});

// Track initialization state
var python_initialized: bool = false;
var numpy_initialized: bool = false;

pub const PythonValue = union(enum) {
    none,
    bool: bool,
    int: i64,
    float: f64,
    string: []const u8,
    list: []PythonValue,
    dict: void,
    object: *c.PyObject,

    pub fn deinit(self: PythonValue, allocator: std.mem.Allocator) void {
        switch (self) {
            .string => |s| allocator.free(s),
            .list => |l| {
                for (l) |item| {
                    item.deinit(allocator);
                }
                allocator.free(l);
            },
            .object => |obj| {
                c.Py_DECREF(obj);
            },
            else => {},
        }
    }
};

pub const PythonError = error{
    NotInitialized,
    AlreadyInitialized,
    ModuleNotFound,
    FunctionNotFound,
    CallFailed,
    ConversionFailed,
    NumPyNotAvailable,
};

/// Initialize Python interpreter. Must be called before any Python operations.
pub fn initialize() PythonError!void {
    if (python_initialized) {
        return error.AlreadyInitialized;
    }

    c.Py_Initialize();

    if (c.Py_IsInitialized() == 0) {
        return error.NotInitialized;
    }

    python_initialized = true;

    // Initialize NumPy if available
    init_numpy() catch {
        // NumPy is optional
        numpy_initialized = false;
    };
}

/// Cleanup Python interpreter.
pub fn finalize() void {
    if (python_initialized) {
        if (numpy_initialized) {
            // NumPy cleanup if needed
            numpy_initialized = false;
        }

        c.Py_Finalize();
        python_initialized = false;
    }
}

/// Check if Python is initialized.
pub fn isInitialized() bool {
    return python_initialized;
}

/// Check if NumPy is available.
pub fn hasNumPy() bool {
    return numpy_initialized;
}

/// Load a Python module by name.
pub fn getModule(name: []const u8) PythonError!*c.PyObject {
    if (!python_initialized) {
        return error.NotInitialized;
    }

    const name_c = std.heap.c_allocator.dupeZ(u8, name) catch {
        return error.ConversionFailed;
    };
    defer std.heap.c_allocator.free(name_c);

    const module = c.PyImport_ImportModule(name_c.ptr);

    if (module == null) {
        c.PyErr_Clear();
        return error.ModuleNotFound;
    }

    return module.?;
}

/// Get a function from a module.
pub fn getFunction(module: *c.PyObject, name: []const u8) PythonError!*c.PyObject {
    const name_c = std.heap.c_allocator.dupeZ(u8, name) catch {
        return error.ConversionFailed;
    };
    defer std.heap.c_allocator.free(name_c);

    const func = c.PyObject_GetAttrString(module, name_c.ptr);

    if (func == null) {
        c.PyErr_Clear();
        return error.FunctionNotFound;
    }

    if (c.PyCallable_Check(func) == 0) {
        c.Py_DECREF(func);
        return error.FunctionNotFound;
    }

    return func.?;
}

/// Call a Python function with arguments.
pub fn callFunction(module_name: []const u8, function_name: []const u8, args: []PythonValue) PythonError!PythonValue {
    if (!python_initialized) {
        return error.NotInitialized;
    }

    // Get module
    const module = try getModule(module_name);
    defer c.Py_DECREF(module);

    // Get function
    const func = try getFunction(module, function_name);
    defer c.Py_DECREF(func);

    // Convert arguments to Python tuple
    const py_args = try zigArgsToPython(args);
    defer c.Py_DECREF(py_args);

    // Call function
    const result = c.PyObject_CallObject(func, py_args);

    if (result == null) {
        c.PyErr_Clear();
        return error.CallFailed;
    }
    defer c.Py_DECREF(result);

    // Convert result back to Zig
    return try pythonToZig(result.?);
}

/// Create a NumPy array from f64 slice.
pub fn numpyArray(data: []const f64) PythonError!PythonValue {
    if (!python_initialized) {
        return error.NotInitialized;
    }

    if (!numpy_initialized) {
        return error.NumPyNotAvailable;
    }

    // Import numpy if not already done
    const np = getModule("numpy") catch {
        return error.NumPyNotAvailable;
    };
    defer c.Py_DECREF(np);

    // Create array using numpy.array
    const array_func = getFunction(np, "array") catch {
        return error.NumPyNotAvailable;
    };
    defer c.Py_DECREF(array_func);

    // Convert data to Python list first
    const py_list = c.PyList_New(@intCast(data.len));
    if (py_list == null) {
        return error.ConversionFailed;
    }

    for (data, 0..) |val, i| {
        const py_val = c.PyFloat_FromDouble(val);
        if (py_val == null) {
            c.Py_DECREF(py_list);
            return error.ConversionFailed;
        }
        // PyList_SetItem steals reference
        _ = c.PyList_SetItem(py_list.?, @intCast(i), py_val.?);
    }

    // Call numpy.array()
    const args = c.PyTuple_New(1);
    if (args == null) {
        c.Py_DECREF(py_list);
        return error.ConversionFailed;
    }
    _ = c.PyTuple_SetItem(args.?, 0, py_list.?);

    const result = c.PyObject_CallObject(array_func, args);
    c.Py_DECREF(args);

    if (result == null) {
        c.PyErr_Clear();
        return error.CallFailed;
    }

    return PythonValue{ .object = result.? };
}

// Helper: Initialize NumPy
fn init_numpy() PythonError!void {
    if (c.import_array() < 0) {
        return error.NumPyNotAvailable;
    }
    numpy_initialized = true;
}

// Helper: Convert Zig values to Python tuple
fn zigArgsToPython(args: []PythonValue) PythonError!*c.PyObject {
    const tuple = c.PyTuple_New(@intCast(args.len));
    if (tuple == null) {
        return error.ConversionFailed;
    }

    for (args, 0..) |arg, i| {
        const py_val = try zigToPython(arg);
        // PyTuple_SetItem steals reference
        _ = c.PyTuple_SetItem(tuple.?, @intCast(i), py_val);
    }

    return tuple.?;
}

// Helper: Convert single Zig value to Python object
fn zigToPython(value: PythonValue) PythonError!*c.PyObject {
    switch (value) {
        .none => {
            c.Py_INCREF(c.Py_None);
            return c.Py_None.?;
        },
        .bool => |b| {
            const py_bool = if (b) c.Py_True else c.Py_False;
            c.Py_INCREF(py_bool);
            return py_bool.?;
        },
        .int => |n| {
            const py_int = c.PyLong_FromLongLong(n);
            if (py_int == null) {
                return error.ConversionFailed;
            }
            return py_int.?;
        },
        .float => |f| {
            const py_float = c.PyFloat_FromDouble(f);
            if (py_float == null) {
                return error.ConversionFailed;
            }
            return py_float.?;
        },
        .string => |s| {
            const py_str = c.PyUnicode_FromStringAndSize(s.ptr, @intCast(s.len));
            if (py_str == null) {
                return error.ConversionFailed;
            }
            return py_str.?;
        },
        .list => |l| {
            const py_list = c.PyList_New(@intCast(l.len));
            if (py_list == null) {
                return error.ConversionFailed;
            }

            for (l, 0..) |item, i| {
                const py_item = try zigToPython(item);
                _ = c.PyList_SetItem(py_list.?, @intCast(i), py_item);
            }

            return py_list.?;
        },
        .dict => {
            const py_dict = c.PyDict_New();
            if (py_dict == null) {
                return error.ConversionFailed;
            }
            return py_dict.?;
        },
        .object => |obj| {
            c.Py_INCREF(obj);
            return obj;
        },
    }
}

// Helper: Convert Python object to Zig value
fn pythonToZig(obj: *c.PyObject) PythonError!PythonValue {
    // Check for None
    if (obj == c.Py_None) {
        return PythonValue{ .none = {} };
    }

    // Check for bool
    if (c.PyBool_Check(obj) != 0) {
        return PythonValue{ .bool = (obj == c.Py_True) };
    }

    // Check for int
    if (c.PyLong_Check(obj) != 0) {
        const val = c.PyLong_AsLongLong(obj);
        if (val == -1 and c.PyErr_Occurred() != null) {
            c.PyErr_Clear();
            return error.ConversionFailed;
        }
        return PythonValue{ .int = val };
    }

    // Check for float
    if (c.PyFloat_Check(obj) != 0) {
        const val = c.PyFloat_AsDouble(obj);
        if (val == -1.0 and c.PyErr_Occurred() != null) {
            c.PyErr_Clear();
            return error.ConversionFailed;
        }
        return PythonValue{ .float = val };
    }

    // Check for string
    if (c.PyUnicode_Check(obj) != 0) {
        const str_ptr = c.PyUnicode_AsUTF8(obj);
        if (str_ptr == null) {
            return error.ConversionFailed;
        }
        const str_len = c.PyUnicode_GET_LENGTH(obj);
        const str = std.heap.c_allocator.dupe(u8, str_ptr.?[0..@intCast(str_len)]) catch {
            return error.ConversionFailed;
        };
        return PythonValue{ .string = str };
    }

    // Check for list
    if (c.PyList_Check(obj) != 0) {
        const len = c.PyList_Size(obj);
        if (len < 0) {
            return error.ConversionFailed;
        }

        var list = std.ArrayList(PythonValue).init(std.heap.c_allocator);
        defer list.deinit();

        var i: isize = 0;
        while (i < len) : (i += 1) {
            const item = c.PyList_GetItem(obj, i);
            if (item == null) {
                return error.ConversionFailed;
            }
            const zig_item = try pythonToZig(item.?);
            try list.append(zig_item);
        }

        return PythonValue{ .list = list.toOwnedSlice() catch {
            return error.ConversionFailed;
        } };
    }

    // Return as opaque object
    c.Py_INCREF(obj);
    return PythonValue{ .object = obj };
}

// Helper: Get string representation of Python object
pub fn pythonRepr(obj: *c.PyObject) []const u8 {
    const repr = c.PyObject_Repr(obj);
    if (repr == null) {
        c.PyErr_Clear();
        return "<repr failed>";
    }
    defer c.Py_DECREF(repr);

    const str_ptr = c.PyUnicode_AsUTF8(repr.?);
    if (str_ptr == null) {
        return "<repr failed>";
    }

    return std.heap.c_allocator.dupe(u8, std.mem.span(str_ptr.?)) catch "<repr failed>";
}
