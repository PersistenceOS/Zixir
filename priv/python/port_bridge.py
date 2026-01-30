#!/usr/bin/env python3
"""
Zixir Python specialist: port bridge.
Reads JSON lines from stdin, dispatches to module.function(*args), writes JSON line to stdout.
Single entry script; wire format and translation in one place.
"""
import sys
import json
import importlib
import traceback


def wire_to_python(obj):
    """Convert wire (JSON-like) to native Python where needed."""
    if isinstance(obj, list):
        return [wire_to_python(x) for x in obj]
    if isinstance(obj, dict):
        return {k: wire_to_python(v) for k, v in obj.items()}
    return obj


def python_to_wire(obj):
    """Convert Python objects to JSON-serializable format."""
    if obj is None:
        return None
    elif isinstance(obj, (int, float, str, bool)):
        return obj
    elif isinstance(obj, (list, tuple)):
        return [python_to_wire(x) for x in obj]
    elif isinstance(obj, dict):
        return {str(k): python_to_wire(v) for k, v in obj.items()}
    elif hasattr(obj, '__iter__') and not isinstance(obj, (str, bytes)):
        try:
            return [python_to_wire(x) for x in obj]
        except:
            return str(obj)
    else:
        return str(obj)


def main():
    # Ensure stdout is line-buffered for proper communication
    try:
        if hasattr(sys.stdout, 'reconfigure'):
            sys.stdout.reconfigure(line_buffering=True)
    except:
        pass
    
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            mod_name = req.get("m", "")
            func_name = req.get("f", "")
            args = wire_to_python(req.get("a", []))
            
            if not mod_name or not func_name:
                out = {"error": "missing m or f"}
            else:
                try:
                    mod = importlib.import_module(mod_name)
                    fn = getattr(mod, func_name)
                    result = fn(*args)
                    out = {"ok": python_to_wire(result)}
                except ImportError as e:
                    out = {"error": f"Module not found: {mod_name} - {str(e)}"}
                except AttributeError as e:
                    out = {"error": f"Function not found: {func_name} in {mod_name} - {str(e)}"}
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
