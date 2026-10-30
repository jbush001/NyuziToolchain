import inspect
import os
import sys


def find_lldb_root():
    lldb_root = os.path.dirname(inspect.getfile(inspect.currentframe()))
    while True:
        parent = os.path.dirname(lldb_root)
        if parent == lldb_root: # dirname('/') == '/'
            break
        lldb_root = parent

        test_path = os.path.join(lldb_root, "use_lldb_suite_root.py")
        if os.path.isfile(test_path):
            return lldb_root
    return None

lldb_root = find_lldb_root()
if lldb_root is not None:
    if sys.version_info[0] < 3:
        import imp
        fp, pathname, desc = imp.find_module("use_lldb_suite_root", [lldb_root])
        try:
            imp.load_module("use_lldb_suite_root", fp, pathname, desc)
        finally:
            if fp:
                fp.close()
    else:
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "use_lldb_suite_root",
            os.path.join(lldb_root, "use_lldb_suite_root.py"))
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
