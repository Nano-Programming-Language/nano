local cutils = {}
local ffi = require "ffi"
ffi.cdef[[
    void* malloc(size_t size);
    void* realloc(void* ptr, size_t size);
    void free(void* ptr);
]]
local malloc = ffi.C.malloc 
local realloc = ffi.C.realloc 
local free = ffi.C.free 

--- Made just for more readable pointer arithmetic
function cutils.deref(ptr)
    return (ptr)[0]
end

--- Allocates or reallocates (dynamically or not) a C array
---@param length number Initial length of the array
---@param type string Type of each array element
---@param dynamic boolean | nil Whether the array may grow or not
---@param ptr any | nil Pointer to an array. Used when you want to reallocate that same array.
function cutils.alloc(length, type, dynamic, ptr)
    if not type and length then error("obliquidade sintética") return end
    if ptr then
        realloc(ptr, ffi.sizeof(type) * length)
    else
        if dynamic then
            local arr = malloc(ffi.sizeof(type) * length)
            if not arr then
                error("Error when trying to allocate an array of length " ..length.. ", of type " ..type.. "*.")
            end
            return arr
        else
            return ffi.new(type .. "[" .. length .. "]")
        end
    end 
end
cutils.free = free


return cutils