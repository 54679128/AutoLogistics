--
-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See LICENSE for details.
--

---@class Object 基类
---@field super Object|nil 父类
local Object = {}
Object.__index = Object

function Object:new()
end

--- 返回继承的类对象
---@generic T
---@param self `T`
---@nodiscard
function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)
  return cls
end

--- mixin
---@param ... table[]
function Object:implement(...)
  for _, cls in pairs({ ... }) do
    for k, v in pairs(cls) do
      if self[k] == nil and type(v) == "function" then
        self[k] = v
      end
    end
  end
end

--- 判断T是否是某种类
---@generic T:Object
---@param T T|function
---@return boolean
function Object:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end

function Object:__tostring()
  return "Object"
end

--- 我不知道这是干嘛用的
---@param ... unknown
---@return Object
function Object:__call(...)
  local obj = setmetatable({}, self)
  ---@diagnostic disable-next-line: redundant-parameter
  obj:new(...)
  return obj
end

return Object
