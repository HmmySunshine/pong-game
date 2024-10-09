--[[
    GD50 2022
    Pong Remake

    -- 主程序 --

    作者：范泽昊
    

    原版由Atari在1972年制作。两个玩家控制球拍，目标是让球穿过对方的边缘。首先达到10分的玩家获胜。
    这个版本在分辨率上更接近NES，但采用宽屏（16:9），因此在现代系统上看起来更好。
]]

-- push 是一个库，它允许我们在虚拟分辨率下绘制游戏，而不是窗口的实际大小；用于提供复古的美学风格
push = require 'push'

-- 我们使用的 "Class" 库将允许我们将游戏中的任何东西表示为代码，而不是跟踪许多分散的变量和方法
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

-- 我们的游戏对象类，用于存储每个球拍的位置和尺寸，以及渲染它们的逻辑
require 'Paddle'

-- 球类，在结构上与球拍相似，但机械上会非常不同
require 'Ball'

-- 实际窗口的大小
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- 我们试图模拟的虚拟分辨率
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- 球拍移动速度
PADDLE_SPEED = 200

--[[
    仅在游戏开始时调用一次；用于设置游戏对象、变量等，并准备游戏世界。
]]
function love.load()
    -- 将love的默认过滤器设置为“最近邻”，这基本上意味着不会对像素进行过滤（模糊），这对于2D游戏来说很重要
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- 设置应用程序窗口的标题
    love.window.setTitle('Pong')

    -- 使用时间作为种子初始化随机数生成器，使随机调用总是随机的
    math.randomseed(os.time())

    -- 初始化我们漂亮的复古文本字体
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    -- 设置我们的音效；稍后，我们可以通过索引这个表并调用每个条目的 `play` 方法来播放音效
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }
    
    -- 初始化我们的虚拟分辨率，它将在实际窗口的任何尺寸下渲染
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = false
    })

    -- 初始化玩家球拍；使其成为全局变量，以便其他函数和模块可以检测到它们
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- 在屏幕中间放置一个球
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- 初始化得分变量
    player1Score = 0
    player2Score = 0

    -- 要么是1要么是2；得分的一方将获得下一轮的服务
    servingPlayer = 1

    -- 获胜的玩家；在游戏结束时设置适当的值
    winningPlayer = 0

    -- 游戏的状态；可以是以下之一：
    -- 1. 'start'（游戏开始之前，第一轮服务之前）
    -- 2. 'serve'（等待按键服务球）
    -- 3. 'play'（球在球拍之间反弹）
    -- 4. 'done'（游戏结束，有胜利者，准备重新开始）
    gameState = 'start'
end

--[[
    当我们改变窗口的尺寸时调用，例如通过拖动窗口的底部角。在这种情况下，我们只需要调用 `push` 来处理调整大小。接受一个 `w` 和 `h` 变量，分别代表宽度和高度。
]]
function love.resize(w, h)
    push:resize(w, h)
end

--[[
    每帧调用一次，传递自上一帧以来的 `dt`。`dt` 是以秒为单位的时间增量。将任何更改乘以 `dt`，可以使我们的游戏在所有硬件上表现一致；否则，任何更改都将尽可能快地应用，并因系统硬件而异。
]]
function love.update(dt)
    if gameState == 'serve' then
        -- 在切换到play之前，根据最后得分的一方初始化球的速度
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        -- 检测球与球拍的碰撞，如果为真则反转dx，然后根据碰撞的位置调整dy，然后播放音效
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            -- 保持速度方向相同，但随机化它
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            -- 保持速度方向相同，但随机化它
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        -- 检测上边界和下边界碰撞，如果为真则反转dy，然后播放音效
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- -4 以考虑球的大小
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- 如果我们达到左或右边缘，返回服务并更新得分和服务玩家
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            -- 如果我们达到10分，游戏结束；将状态设置为done，以便我们可以显示胜利消息
            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                -- 将球放在屏幕中间，没有速度
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end

    --
    -- 无论我们处于什么状态，球拍都可以移动
    --
    -- 玩家1
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- 玩家2
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- 仅在play状态下更新球，基于其DX和DY；将速度乘以dt，使运动与帧率无关
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

--[[
    当按键发生时调用，只调用一次。不处理按住键的情况，这由一个单独的函数（`love.keyboard.isDown`）处理。当我们要立即发生事情时很有用，只需一次，比如我们想退出。
]]
function love.keypressed(key)
    -- `key` 将是此回调检测到的按下的键
    if key == 'escape' then
        -- LÖVE2D用于退出应用程序的函数
        love.event.quit()
    -- 如果我们在开始或服务阶段按下回车键，它应该过渡到下一个适当的状态
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- 游戏只是重新启动阶段，但将服务玩家设置为获胜者的对手，以保持公平！
            gameState = 'serve'

            ball:reset()

            -- 将得分重置为0
            player1Score = 0
            player2Score = 0

            -- 决定服务玩家为获胜者的对手
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

--[[
    每帧调用一次，仅用于绘制游戏对象和更多内容到屏幕上。
]]
function love.draw()
    -- 使用push开始绘制，在虚拟分辨率下
    push:start()

    love.graphics.clear(40/255, 45/255, 52/255, 255/255)
    
    -- 根据我们处于的游戏阶段渲染不同的内容
    if gameState == 'start' then
        -- 用户界面消息
        love.graphics.setFont(smallFont)
        love.graphics.printf('weclomePong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Enter BgeinGame!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        -- 用户界面消息
        love.graphics.setFont(smallFont)
        love.graphics.printf('Plyaer' .. tostring(servingPlayer) .. "Server!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('PressEnterServer!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- 播放阶段没有要显示的用户界面消息
    elseif gameState == 'done' then
        -- 用户界面消息
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player' .. tostring(winningPlayer) .. 'Win!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('PressEnterRestartGame!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    -- 在渲染球之前显示得分
    displayScore()
    
    player1:render()
    player2:render()
    ball:render()

    -- 显示FPS以进行调试；简单注释掉以移除
    displayFPS()

    -- 结束绘制到push
    push:finish()
end

--[[
    简单的函数，用于渲染得分。
]]
function displayScore()
    -- 得分显示
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end

--[[
   渲染当前fps
]]
function displayFPS()
    
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255/255, 0, 255/255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(255, 255, 255, 255)
end
