#!/usr/bin/env python3
"""
Zixir Python specialist: enhanced port bridge.
Reads JSON lines from stdin, dispatches to module.function(*args), writes JSON line to stdout.
Supports numpy arrays, pandas DataFrames, and efficient data serialization.
"""
import sys
import json
import importlib
import traceback
import base64
import struct

# Optional imports - handle gracefully if not available
try:
    import numpy as np
    NUMPY_AVAILABLE = True
except ImportError:
    NUMPY_AVAILABLE = False

try:
    import pandas as pd
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False


def wire_to_python(obj):
    """Convert wire (JSON-like) to native Python with special type handling."""
    if isinstance(obj, dict):
        # Check for special type markers
        if "__numpy_array__" in obj and NUMPY_AVAILABLE:
            return decode_numpy_array(obj["__numpy_array__"])
        elif "__pandas_df__" in obj and PANDAS_AVAILABLE:
            return decode_pandas_df(obj["__pandas_df__"])
        elif "__bytes__" in obj:
            return base64.b64decode(obj["__bytes__"])
        else:
            return {k: wire_to_python(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [wire_to_python(x) for x in obj]
    else:
        return obj


def python_to_wire(obj):
    """Convert Python objects to JSON-serializable format with special handling."""
    if obj is None:
        return None
    elif isinstance(obj, (int, float, str, bool)):
        return obj
    elif isinstance(obj, bytes):
        return {"__bytes__": base64.b64encode(obj).decode('ascii')}
    elif isinstance(obj, (list, tuple)):
        return [python_to_wire(x) for x in obj]
    elif isinstance(obj, dict):
        return {str(k): python_to_wire(v) for k, v in obj.items()}
    elif NUMPY_AVAILABLE and isinstance(obj, np.ndarray):
        return {"__numpy_array__": encode_numpy_array(obj)}
    elif PANDAS_AVAILABLE and isinstance(obj, pd.DataFrame):
        return {"__pandas_df__": encode_pandas_df(obj)}
    elif PANDAS_AVAILABLE and isinstance(obj, pd.Series):
        return {"__numpy_array__": encode_numpy_array(obj.values)}
    elif hasattr(obj, '__iter__') and not isinstance(obj, (str, bytes)):
        try:
            return [python_to_wire(x) for x in obj]
        except:
            return str(obj)
    else:
        return str(obj)


def encode_numpy_array(arr):
    """Encode numpy array to compact base64 format."""
    dtype_map = {
        np.float64: 'f64', np.float32: 'f32',
        np.int64: 'i64', np.int32: 'i32',
        np.int16: 'i16', np.int8: 'i8',
        np.uint64: 'u64', np.uint32: 'u32',
        np.uint16: 'u16', np.uint8: 'u8',
    }
    
    dtype_str = dtype_map.get(arr.dtype.type, 'f64')
    shape = arr.shape
    
    # Convert to bytes and base64 encode
    raw_bytes = arr.tobytes()
    encoded = base64.b64encode(raw_bytes).decode('ascii')
    
    return {
        "dtype": dtype_str,
        "shape": shape,
        "data": encoded
    }


def decode_numpy_array(arr_info):
    """Decode numpy array from compact base64 format."""
    if not NUMPY_AVAILABLE:
        raise ImportError("numpy not available")
    
    dtype_map = {
        'f64': np.float64, 'f32': np.float32,
        'i64': np.int64, 'i32': np.int32,
        'i16': np.int16, 'i8': np.int8,
        'u64': np.uint64, 'u32': np.uint32,
        'u16': np.uint16, 'u8': np.uint8,
    }
    
    dtype = dtype_map.get(arr_info["dtype"], np.float64)
    shape = tuple(arr_info["shape"])
    raw_bytes = base64.b64decode(arr_info["data"])
    
    # Reconstruct array
    arr = np.frombuffer(raw_bytes, dtype=dtype)
    if shape:
        arr = arr.reshape(shape)
    
    return arr


def encode_pandas_df(df):
    """Encode pandas DataFrame to wire format."""
    return {
        "columns": list(df.columns),
        "data": encode_numpy_array(df.values),
        "index": list(df.index) if not isinstance(df.index, pd.RangeIndex) else None
    }


def decode_pandas_df(df_info):
    """Decode pandas DataFrame from wire format."""
    if not PANDAS_AVAILABLE:
        raise ImportError("pandas not available")
    
    data = decode_numpy_array(df_info["data"])
    columns = df_info["columns"]
    index = df_info.get("index")
    
    df = pd.DataFrame(data, columns=columns)
    if index:
        df.index = index
    
    return df


def main():
    # Ensure stdout is line-buffered for proper communication
    try:
        if hasattr(sys.stdout, 'reconfigure'):
            sys.stdout.reconfigure(line_buffering=True)
    except:
        pass
    
    # Send ready signal
    sys.stdout.write(json.dumps({"ready": True, "numpy": NUMPY_AVAILABLE, "pandas": PANDAS_AVAILABLE}) + "\n")
    sys.stdout.flush()
    
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            
            # Handle special commands
            if "cmd" in req:
                cmd = req["cmd"]
                if cmd == "ping":
                    sys.stdout.write(json.dumps({"ok": "pong"}) + "\n")
                    sys.stdout.flush()
                    continue
                elif cmd == "health":
                    health = {
                        "ok": True,
                        "numpy": NUMPY_AVAILABLE,
                        "pandas": PANDAS_AVAILABLE,
                        "python_version": sys.version_info[:2]
                    }
                    sys.stdout.write(json.dumps({"ok": health}) + "\n")
                    sys.stdout.flush()
                    continue
            
            mod_name = req.get("m", "")
            func_name = req.get("f", "")
            args = wire_to_python(req.get("a", []))
            kwargs = wire_to_python(req.get("k", {}))
            
            if not mod_name or not func_name:
                out = {"error": "missing m or f"}
            else:
                try:
                    mod = importlib.import_module(mod_name)
                    fn = getattr(mod, func_name)
                    
                    # Call function with args and kwargs
                    if kwargs:
                        result = fn(*args, **kwargs)
                    else:
                        result = fn(*args)
                    
                    out = {"ok": python_to_wire(result)}
                except ImportError as e:
                    out = {"error": f"Module not found: {mod_name} - {str(e)}"}
                except AttributeError as e:
                    out = {"error": f"Function not found: {func_name} in {mod_name} - {str(e)}"}
                except TypeError as e:
                    out = {"error": f"Type error: {str(e)}"}
                except ValueError as e:
                    out = {"error": f"Value error: {str(e)}"}
                except Exception as e:
                    error_msg = f"{type(e).__name__}: {str(e)}"
                    out = {"error": error_msg}
        except json.JSONDecodeError as e:
            out = {"error": f"Invalid JSON: {str(e)}"}
        except Exception as e:
            out = {"error": f"Bridge error: {str(e)}"}
        
        sys.stdout.write(json.dumps(out) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
