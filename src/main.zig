const rl = @import("raylib");
const std = @import("std");
const Vector2 = rl.Vector2;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

const screenWidth = 1000;
const screenHeight = 800;

const gravity: f32 = 0.5;
const borderWidth = 36;
const borderBounds = rl.Rectangle.init(borderWidth, borderWidth, screenWidth - borderWidth, screenHeight - borderWidth);
const middleWallHeight = 300;
const middleWallBounds = rl.Rectangle.init(screenWidth / 2 - borderWidth / 2, borderBounds.height - middleWallHeight, borderWidth, middleWallHeight);
const middleWallTop = rl.Rectangle.init(screenWidth / 2 - borderWidth / 2, borderBounds.height - middleWallHeight, borderWidth, 1);
const middleWallRight = rl.Rectangle.init(screenWidth / 2 - borderWidth / 2 + borderWidth, borderBounds.height - middleWallHeight + 10, 1, middleWallHeight);
const middleWallLeft = rl.Rectangle.init(screenWidth / 2 - borderWidth / 2, borderBounds.height - middleWallHeight + 10, 1, middleWallHeight);

const random = std.crypto.random;

const State = struct { scores: [2]u32 = undefined, winScore: u32 = 7, startWaitTime: f32 = 3, currentWaitTime: f32 = 0, playing: bool = false };

const Player = struct {
    id: f32,
    pos: Vector2,
    vel: Vector2,
    dim: Vector2 = Vector2.init(80, 120),
    speed: f32 = 5,
    onGround: bool = false,
    color: rl.Color = rl.Color.white,
};

const Ball = struct {
    pos: Vector2,
    vel: Vector2,
    size: f32 = 26,
    color: rl.Color = rl.Color.white,
};

var player0 = Player{
    .id = 0,
    .pos = Vector2.init(100, 300),
    .vel = Vector2.init(0, 0),
};

var player1 = Player{
    .id = 1,
    .pos = Vector2.init(500, 300),
    .vel = Vector2.init(0, 0),
};

var ball = Ball{
    .pos = Vector2.init(screenWidth / 2 - 26 / 2, screenHeight / 2 - 100),
    .vel = Vector2.init(0, 0),
};

var state: State = undefined;

pub fn init() !void {
    state = State{
        .scores = .{ 0, 0 },
        .winScore = 7,
        .startWaitTime = 3,
        .currentWaitTime = 0,
    };

    try startRound();
}

pub fn run() !void {
    try init();
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        try update();
        try render();
    }
}

pub fn update() !void {
    if (!state.playing) {
        state.currentWaitTime += rl.getFrameTime();
        if (state.currentWaitTime >= state.startWaitTime) {
            state.playing = true;
            try startRound();
        }
    }

    try updatePlayer(&player0);
    try updatePlayer(&player1);
    try updateBall();
}

pub fn render() !void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.black);

    try renderBorder();

    // render middle wall
    rl.drawRectangleRec(middleWallBounds, rl.Color.white);

    try renderPlayer(&player0);
    try renderPlayer(&player1);

    // render ball
    rl.drawRectangleV(ball.pos, Vector2.init(ball.size, ball.size), ball.color);

    try renderGUI();
}

pub fn onEndRound() !void {
    if (ball.pos.x < screenWidth / 2) {
        state.scores[1] += 1;
    } else {
        state.scores[0] += 1;
    }

    if(state.scores[0] >= state.winScore or state.scores[1] >= state.winScore) {
        state.scores[0] = 0;
        state.scores[1] = 0;
    }

    std.debug.print("Player 0: {}, Player 1: {}\n", .{ state.scores[0], state.scores[1] });
    try restartRound();
    try startRound();
}

pub fn restartRound() !void {
    ball.pos = Vector2.init(screenWidth / 2 - 26 / 2, screenHeight / 2 - 100);
    ball.vel = Vector2.init(0, 0);
    state.currentWaitTime = 0;
    state.playing = false;
}

pub fn startRound() !void {
    const x = std.rand.float(random, f32);
    ball.vel = Vector2.init(3 + x, -13);
}

pub fn updatePlayer(p: *Player) !void {
    p.vel.y += gravity;
    if (p.onGround) {
        p.vel.y = 0;
    }

    if ((p.id == 0 and rl.isKeyDown(.right)) or (p.id == 1 and rl.isKeyDown(.d))) {
        p.pos.x += p.speed;
    }
    if ((p.id == 0 and rl.isKeyDown(.left)) or (p.id == 1 and rl.isKeyDown(.a))) {
        p.pos.x -= p.speed;
    }

    const ownLimits = rl.Rectangle.init(borderBounds.x + (screenWidth / 2 - borderWidth / 2) * p.id, 0, (screenWidth / 2 - borderWidth * 1.5), borderBounds.height);
    //rl.drawRectangleLinesEx(ownLimits, 2, rl.Color.green);

    if (p.pos.x < ownLimits.x) {
        p.pos.x = ownLimits.x;
    }

    if (p.pos.x > ownLimits.width - p.dim.x + ownLimits.x) {
        p.pos.x = ownLimits.width - p.dim.x + ownLimits.x;
    }

    if ((p.id == 0 and rl.isKeyDown(.up)) or (p.id == 1 and rl.isKeyDown(.w))) {
        if (p.onGround) {
            p.vel.y = -p.speed * 2;
            p.onGround = false;
        }
    }

    p.pos.y += p.vel.y;

    const floorY = borderBounds.height - p.dim.y;
    if (p.pos.y >= floorY) {
        p.pos.y = floorY;
        p.vel.y = 0;
        p.onGround = true;
    }
}

pub fn renderPlayer(p: *Player) !void {
    const pixelW = p.dim.x / 3;
    const pixelH = p.dim.y / 5;
    rl.drawRectangleV(p.pos, Vector2.init(pixelW, p.dim.y), p.color);
    rl.drawRectangleV(Vector2.init(p.pos.x + pixelW * 2, p.pos.y), Vector2.init(pixelW, p.dim.y), p.color);
    rl.drawRectangleV(Vector2.init(p.pos.x + pixelW * 1, p.pos.y + pixelH), Vector2.init(pixelW, pixelH * 2), p.color);
}

pub fn updateBall() !void {
    ball.vel.y += gravity;
    ball.pos.y += ball.vel.y;
    ball.pos.x += ball.vel.x;

    if (ball.pos.x < borderBounds.x) {
        ball.pos.x = borderBounds.x;
        ball.vel.x *= -1;
    }

    if (ball.pos.x > borderBounds.width - ball.size) {
        ball.pos.x = borderBounds.width - ball.size;
        ball.vel.x *= -1;
    }

    try ballHandlePlayerCollision(if (ball.pos.x > screenWidth / 2) &player1 else &player0);
    try ballHandleMiddleWallCollision();

    if (ball.pos.y > borderBounds.height - ball.size) {
        try onEndRound();
    }
}

pub fn ballHandlePlayerCollision(p: *Player) !void {
    const prevBallPos = Vector2.init(ball.pos.x - ball.vel.x, ball.pos.y - ball.vel.y);
    const prevPlayerPos = Vector2.init(p.pos.x - p.vel.x, p.pos.y - p.vel.y);

    if (prevBallPos.y < prevPlayerPos.y and rl.checkCollisionCircleRec(ball.pos, ball.size, rl.Rectangle.init(p.pos.x, p.pos.y, p.dim.x, p.dim.y))) {
        const v_factor = ((ball.pos.x - p.pos.x + ball.size) / (ball.size + p.dim.x)) - 0.5;
        ball.vel.x = v_factor * 25;
        ball.vel.y = -2 * @abs(5 + p.vel.y * 1.9);
    }
}

pub fn ballHandleMiddleWallCollision() !void {
    const ballBounds = rl.Rectangle.init(ball.pos.x, ball.pos.y, ball.size, ball.size);
    if (rl.checkCollisionRecs(ballBounds, middleWallTop)) {
        ball.vel.y *= -1;
    }

    if (rl.checkCollisionRecs(ballBounds, middleWallRight) or rl.checkCollisionRecs(ballBounds, middleWallLeft)) {
        ball.vel.x *= -1;
    }
}

pub fn renderBorder() !void {
    rl.drawRectangleLinesEx(rl.Rectangle{ .x = 0, .y = 0, .width = screenWidth, .height = screenHeight }, borderWidth, rl.Color.white);
}

pub fn renderGUI() !void {
    rl.drawText("GRENADE BROTHERS", 290, 40, 40, rl.Color.white);
    var buff: [2:0]u8 = undefined;
    const slice = try std.fmt.bufPrint(&buff, "{d}", .{state.scores[0]});
    buff[slice.len] = 0;
    rl.drawText(&buff, 50, 40, 100, rl.Color.white);

    const slc = try std.fmt.bufPrint(&buff, "{d}", .{state.scores[1]});
    buff[slc.len] = 0;
    rl.drawText(&buff, screenWidth-100, 40, 100, rl.Color.white);
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    rl.initWindow(screenWidth, screenHeight, "GRENADE BROTHERS");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    try run();
}

