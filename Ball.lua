
Ball = Class{}

function Ball:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- 这些变量用于跟踪在X和Y轴上的速度，因为球可以在两个维度上移动
    self.dy = 0
    self.dx = 0
end

--[[
    期望一个球拍作为参数，并根据它们的矩形是否重叠返回true或false。
]]
function Ball:collides(paddle)
    -- 首先，检查任一边的左边缘是否比另一边的右边缘更靠右
    if self.x > paddle.x + paddle.width or paddle.x > self.x + self.width then
        return false
    end

    -- 然后，检查任一边的底部边缘是否比另一边的顶部边缘更高
    if self.y > paddle.y + paddle.height or paddle.y > self.y + self.height then
        return false
    end 

    -- 如果上述条件都不满足，则它们重叠
    return true
end

--[[
    将球放在屏幕中间，没有移动。
]]
function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2
    self.dx = 0
    self.dy = 0
end

function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Ball:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end