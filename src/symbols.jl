@apisetup begin
    PyObject_GetAttrString = PySym(:PyObject_GetAttrString)
    PyCFunction_NewEx = PySym(:PyCFunction_NewEx)
    
    # object
    PyObject_Str = PySym(:PyObject_Str)
    PyObject_VectorcallDict = PySymMaybe(:PyObject_VectorcallDict)
    PyObject_CallFunctionObjArgs = PySym(:PyObject_CallFunctionObjArgs)
    PyObject_CallMethodObjArgs = PySym(:PyObject_CallMethodObjArgs)
    PyObject_GetItem = PySym(:PyObject_GetItem)
    PyObject_SetItem = PySym(:PyObject_SetItem)
    PyObject_RichCompare = PySym(:PyObject_RichCompare)
    PyObject_IsInstance = PySym(:PyObject_IsInstance)
    PyObject_SetAttr = PySym(:PyObject_SetAttr)
    PyObject_GetAttr = PySym(:PyObject_GetAttr)

    # sequence
    PySequence_Length = PySym(:PySequence_Length)
    PySequence_GetItem = PySym(:PySequence_GetItem)
    
    # number
    PyNumber_AsSsize_t = PySym(:PyNumber_AsSsize_t)
    PyNumber_Long = PySym(:PyNumber_Long)

    # unicode
    PyUnicode_FromString = PySym(:PyUnicode_FromString)

    # int/long.
    # Int-prefixed means it's not an exported symbol from libpython
    # TODO: refactor names.
    Py_IntAsNumber = unsafe_load(reinterpret(Ptr{PyTypeObject}, PyO.int)).tp_as_number
    PyInt_Compare = unsafe_load(reinterpret(Ptr{PyTypeObject}, PyO.int)).tp_richcompare
    Py_IntPow = unsafe_load(Py_IntAsNumber).nb_power
    Py_IntAddInt = unsafe_load(Py_IntAsNumber).nb_add
    PyLong_AsDouble = PySym(:PyLong_AsDouble)
    PyLong_AsSsize_t = PySym(:PyLong_AsSsize_t)
    PyLong_FromSsize_t = PySym(:PyLong_FromSsize_t)
    PyLong_FromLong = PySym(:PyLong_FromLong)
    PyLong_FromSize_t = PySym(:PyLong_FromSize_t)

    # float
    PyFloat_FromDouble = PySym(:PyFloat_FromDouble)

    # bytes
    _PyBytes_Join = PySym(:_PyBytes_Join)

    # dict
    _PyDict_GetItem_KnownHash = PySym(:_PyDict_GetItem_KnownHash)
    PyDict_GetItemWithError = PySym(:PyDict_GetItemWithError)


    # list
    PyList_Append = PySym(:PyList_Append)
    PyList_GetItem = PySym(:PyList_GetItem)
    PyList_SetItem = PySym(:PyList_SetItem)
    PyList_New = PySym(:PyList_New)
    
    # function
    PyFunction_GetGlobals = PySym(:PyFunction_GetGlobals)
    
    # module
    PyModule_GetDict = PySym(:PyModule_GetDict)

    # exc
    PyExc_KeyError = PySym(:PyExc_KeyError)
    PyExc_TypeError = PySym(:PyExc_TypeError)

    # err
    PyErr_Clear = PySym(:PyErr_Clear)
    PyErr_SetString = PySym(:PyErr_SetString)
    PyErr_Print = PySym(:PyErr_Print)
    PyErr_ExceptionMatches = PySym(:PyErr_ExceptionMatches)
    PyErr_Occurred = PySym(:PyErr_Occurred)
    PyErr_SetObject = PySym(:PyErr_SetObject)
    PyErr_SetNone = PySym(:PyErr_SetNone)
end
