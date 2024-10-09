

Paddle = Class{}

--[[
    我们类的 `init` 函数只在对象第一次创建时调用一次。用于设置类中的所有变量，并使其准备好使用。

    我们的球拍应该接受一个X和Y，用于定位，以及一个宽度和高度，用于其尺寸。

    注意，`self`是对当前被调用的对象的引用。不同的对象可以有它们自己的x、y、宽度和高度值，从而作为数据的容器。在这个意义上，它们与C语言中的结构体非常相似。
]]
function Paddle:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dy = 0
end

function Paddle:update(dt)
    -- math.max在这里确保我们至少是0或玩家当前按上键计算出的Y位置，这样我们就不会进入负数；移动计算只是我们之前定义的球拍速度乘以dt
    if self.dy < 0 then
        self.y = math.max(0, self.y + self.dy * dt)
    -- 与之前类似，这次我们使用math.min确保我们不会超过屏幕底部减去球拍高度的位置（否则它将部分低于屏幕，因为位置是基于其左上角的）
    else
        self.y = math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt)
    end
end

--[[
    应该在 `love.draw` 中的主函数中调用，理想情况下。使用LÖVE2D的 `rectangle` 函数，它接受一个绘制模式作为第一个参数，以及矩形的位置和尺寸。要改变颜色，必须调用 `love.graphics.setColor`。在LÖVE2D的最新版本中，甚至可以绘制圆角矩形！
]]
function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end