// Python Bridge for Zixir (Phase 2)
// Direct Python C API integration via Zig FFI
// Replaces port-based communication with zero-overhead calls

const std = @import("std");
const c = @cImport({
    @cInclude("Python.h");
});

var python_initialized = false;
var gil_held = false;
var thread_state: *c.PyThreadState = undefined;

// Initialize Python interpreter
pub fn initialize() !void {
    if (python_initialized) return;

    c.Py_Initialize();

    if (c.Py_IsInitialized() == 0) {
        return error.PythonInitFailed;
    }

    python_initialized = true;

    // Import common modules
    _ = get_module("sys") catch {};
    _ = get_module("builtins") catch {};
}

// Cleanup Python interpreter
pub fn finalize() void {
    if (!python_initialized) return;

    if (gil_held) {
        c.PyGILState_Release(c.PyGILState_LOCKED);
        gil_held = false;
    }

    c.Py_Finalize();
    python_initialized = false;
}

// Ensure GIL is held
fn ensure_gil() void {
    if (!gil_held) {
        _ = c.PyGILState_Ensure();
        gil_held = true;
    }
}

// Get Python module
pub fn get_module(name: []const u8) !*c.PyObject {
    ensure_gil();

    const c_name = try std.heap.c_allocator.dupeZ(u8, name);
    defer std.heap.c_allocator.free(c_name);

    const module = c.PyImport_ImportModule(c_name.ptr);
    if (module == null) {
        c.PyErr_Print();
        return error.ModuleImportFailed;
    }

    return module.?;
}

// Call Python function
pub fn call_function(module: []const u8, function: []const u8, args: []const PythonValue) !PythonValue {
    ensure_gil();

    const mod = try get_module(module);
    defer c.Py_DECREF(mod);

    const c_func = try std.heap.c_allocator.dupeZ(u8, function);
    defer std.heap.c_allocator.free(c_func);

    const func = c.PyObject_GetAttrString(mod, c_func.ptr);
    if (func == null) {
        c.PyErr_Print();
        return error.FunctionNotFound;
    }
    defer c.Py_DECREF(func.?);

    // Build argument tuple
    const tuple = c.PyTuple_New(@intCast(args.len));
    if (tuple == null) {
        return error.TupleCreationFailed;
    }
    defer c.Py_DECREF(tuple.?);

    for (args, 0..) |arg, i| {
        const py_arg = try zixir_to_python(arg);
        // PyTuple_SetItem steals reference, so no DECREF needed
        _ = c.PyTuple_SetItem(tuple.?, @intCast(i), py_arg);
    }

    // Call function
    const result = c.PyObject_CallObject(func.?, tuple.?);
    if (result == null) {
        c.PyErr_Print();
        return error.FunctionCallFailed;
    }

    return try python_to_zixir(result.?);
}

// Python value types
pub const PythonValue = union(enum) {
    none,
    bool: bool,
    int: i64,
    float: f64,
    string: []const u8,
    list: []PythonValue,
    dict: std.StringHashMap(PythonValue),
    object: *c.PyObject, // Raw Python object (needs DECREF)

    pub fn deinit(self: PythonValue, alloc: std.mem.Allocator) void {
        switch (self) {
            .string => |s| alloc.free(s),
            .list => |l| {
                for (l) |item| item.deinit(alloc);
                alloc.free(l);
            },
            .dict => |d| {
                var it = d.iterator();
                while (it.next()) |entry| {
                    alloc.free(entry.key_ptr.*);
                    entry.value_ptr.deinit(alloc);
                }
                d.deinit();
            },
            .object => |o| c.Py_DECREF(o),
            else => {},
        }
    }
};

// Convert Zixir value to Python object
fn zixir_to_python(value: PythonValue) !*c.PyObject {
    return switch (value) {
        .none => c.Py_None,
        .bool => |b| if (b) c.Py_True else c.Py_False,
        .int => |n| c.PyLong_FromLongLong(n),
        .float => |f| c.PyFloat_FromDouble(f),
        .string => |s| c.PyUnicode_FromStringAndSize(s.ptr, @intCast(s.len)),
        .list => |l| blk: {
            const py_list = c.PyList_New(@intCast(l.len));
            if (py_list == null) return error.ListCreationFailed;

            for (l, 0..) |item, i| {
                const py_item = try zixir_to_python(item);
                // PyList_SetItem steals reference
                _ = c.PyList_SetItem(py_list.?, @intCast(i), py_item);
            }
            break :blk py_list.?;
        },
        .dict => |d| blk: {
            const py_dict = c.PyDict_New();
            if (py_dict == null) return error.DictCreationFailed;

            var it = d.iterator();
            while (it.next()) |entry| {
                const py_key = c.PyUnicode_FromString(entry.key_ptr.ptr);
                const py_val = try zixir_to_python(entry.value_ptr.*);
                _ = c.PyDict_SetItem(py_dict.?, py_key.?, py_val);
                c.Py_DECREF(py_key.?);
                c.Py_DECREF(py_val);
            }
            break :blk py_dict.?;
        },
        .object => |o| blk: {
            c.Py_INCREF(o);
            break :blk o;
        },
    };
}

// Convert Python object to Zixir value
fn python_to_zixir(obj: *c.PyObject) !PythonValue {
    if (obj == c.Py_None) {
        return PythonValue{ .none = {} };
    }

    if (c.PyBool_Check(obj) == 1) {
        return PythonValue{ .bool = obj == c.Py_True };
    }

    if (c.PyLong_Check(obj) == 1) {
        return PythonValue{ .int = c.PyLong_AsLongLong(obj) };
    }

    if (c.PyFloat_Check(obj) == 1) {
        return PythonValue{ .float = c.PyFloat_AsDouble(obj) };
    }

    if (c.PyUnicode_Check(obj) == 1) {
        var size: c.Py_ssize_t = 0;
        const data = c.PyUnicode_AsUTF8AndSize(obj, &size);
        if (data == null) return error.StringConversionFailed;

        const str = try std.heap.c_allocator.dupe(u8, data.?[0..@intCast(size)]);
        return PythonValue{ .string = str };
    }

    if (c.PyList_Check(obj) == 1) {
        const len = c.PyList_Size(obj);
        var list = try std.heap.c_allocator.alloc(PythonValue, @intCast(len));

        var i: c.Py_ssize_t = 0;
        while (i < len) : (i += 1) {
            const item = c.PyList_GetItem(obj, i);
            c.Py_INCREF(item);
            list[@intCast(i)] = try python_to_zixir(item);
            c.Py_DECREF(item);
        }

        return PythonValue{ .list = list };
    }

    if (c.PyDict_Check(obj) == 1) {
        var dict = std.StringHashMap(PythonValue).init(std.heap.c_allocator);

        var key: *c.PyObject = undefined;
        var value: *c.PyObject = undefined;
        var pos: c.Py_ssize_t = 0;

        while (c.PyDict_Next(obj, &pos, &key, &value) == 1) {
            const key_str = try python_to_zixir(key);
            if (key_str != .string) continue;

            c.Py_INCREF(value);
            const val = try python_to_zixir(value);
            c.Py_DECREF(value);

            try dict.put(key_str.string, val);
        }

        return PythonValue{ .dict = dict };
    }

    // Return as raw object for advanced use
    c.Py_INCREF(obj);
    return PythonValue{ .object = obj };
}

// Convenience functions for common operations
pub fn numpy_array(data: []const f64) !PythonValue {
    const numpy = try get_module("numpy");
    defer c.Py_DECREF(numpy);

    // Create array from slice
    const args = [_]PythonValue{PythonValue{ .list = try slice_to_list(data) }};
    return call_function("numpy", "array", &args);
}

fn slice_to_list(data: []const f64) ![]PythonValue {
    var list = try std.heap.c_allocator.alloc(PythonValue, data.len);
    for (data, 0..) |item, i| {
        list[i] = PythonValue{ .float = item };
    }
    return list;
}

// Error handling
pub fn check_error() !void {
    if (c.PyErr_Occurred() != null) {
        c.PyErr_Print();
        return error.PythonError;
    }
}
