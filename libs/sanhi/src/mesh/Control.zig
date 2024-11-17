const lib = @import("../lib.zig");
const modules = lib.modules;
const backend = lib.backend;
const zglfw = lib.zglfw;
const stdmath = @import("std").math;
const math = @import("math");
const Vector2D = math.Vector2D;
const Vector3D = math.Vector3D;
const Mat4 = math.Matrix4D;
const Mat3 = math.Matrix3D;
const QuaternionD = math.QuaternionD;
const MouseButton = zglfw.MouseButton;
const Action = zglfw.Action;
const Window = zglfw.Window;
const Mods = zglfw.Mods;
const Camera = @import("./Camera.zig");
pub const KEYS = enum { LEFT, UP, RIGHT, BOTTOM };
pub const _STATE = enum(i32) { NONE = -1, ROTATE = 0, DOLLY = 1, PAN = 2, TOUCH_ROTATE = 3, TOUCH_PAN = 4, TOUCH_DOLLY_PAN = 5, TOUCH_DOLLY_ROTATE = 6 };
const Spherical = struct {
    radius: f64 = 1.0,
    phi: f64 = 0, // polar angle
    theta: f64 = 0, // azimuthal angle
    pub fn default() Spherical {
        return .{};
    }
    pub fn init(radius: f64, phi: f64, theta: f64) Spherical {
        return Spherical{
            .radius = radius,
            .phi = phi,
            .theta = theta,
        };
    }

    pub fn set(self: *Spherical, radius: f64, phi: f64, theta: f64) void {
        self.radius = radius;
        self.phi = phi;
        self.theta = theta;
    }

    pub fn copy(self: *Spherical, other: *const Spherical) void {
        self.radius = other.radius;
        self.phi = other.phi;
        self.theta = other.theta;
    }

    // restrict phi to be between EPS and PI-EPS
    pub fn makeSafe(self: *Spherical) void {
        const EPS = 0.000001;
        self.phi = @max(EPS, @min(stdmath.pi - EPS, self.phi));
    }

    pub fn setFromVector3(self: *Spherical, v: *const Vector3D) void {
        self.setFromCartesianCoords(v.x(), v.y(), v.z());
    }

    pub fn setFromCartesianCoords(self: *Spherical, x: f64, y: f64, z: f64) void {
        self.radius = stdmath.sqrt(x * x + y * y + z * z);

        if (self.radius == 0) {
            self.theta = 0;
            self.phi = 0;
        } else {
            self.theta = stdmath.atan2(x, z);
            self.phi = stdmath.acos(clamp(y / self.radius, -1.0, 1.0));
        }
    }
    pub fn clone(self: *const Spherical) Spherical {
        var newSpherical = Spherical{};
        newSpherical.copy(self);
        return newSpherical;
    }
    pub fn clamp(value: f64, minVal: f64, maxVal: f64) f64 {
        return @max(minVal, @min(maxVal, value));
    }
};
const GLFW_PRESS = 1; // GLFW 按钮按下状态

pub const OrbitControl = struct {
    camera: *Camera,
    target: Vector3D = Vector3D.fromZero(),
    cursor: Vector3D = Vector3D.fromZero(),
    minDistance: f64 = 0,
    maxDistance: f64 = stdmath.inf(f64),
    minZoom: f64 = 0,
    maxZoom: f64 = stdmath.inf(f64),

    minTargetRadius: f64 = 0,
    maxTargetRadius: f64 = stdmath.inf(f64),

    minPolarAngle: f64 = 0,
    maxPolarAngle: f64 = stdmath.pi,

    minAzimuthAngle: f64 = -stdmath.inf(f64),
    maxAzimuthAngle: f64 = stdmath.inf(f64),

    enableDamping: bool = false,
    dampingFactor: f64 = 0.05,

    enableZoom: bool = true,
    zoomSpeed: f64 = 1.0,

    enableRotate: bool = true,
    rotateSpeed: f64 = 1.0,

    enablePan: bool = true,
    panSpeed: f64 = 1.0,
    screenSpacePanning: bool = true,
    keyPanSpeed: f64 = 7.0,
    zoomToCursor: bool = false,

    autoRotate: bool = false,
    autoRotateSpeed: f64 = 2.0,

    target0: Vector3D = Vector3D.fromZero(),
    position0: Vector3D = Vector3D.fromZero(),
    zoom0: f64 = 0,

    _lastPosition: Vector3D = Vector3D.fromZero(),
    _lastQuaternion: QuaternionD = QuaternionD.fromZero(),
    _lastTargetPosition: Vector3D = Vector3D.fromZero(),

    _quat: QuaternionD = QuaternionD.fromZero(),
    _quatInverse: QuaternionD = QuaternionD.fromZero(),

    _spherical: Spherical = Spherical.default(),
    _sphericalDelta: Spherical = Spherical.default(),

    _scale: f64 = 1,
    _panOffset: Vector3D = Vector3D.fromZero(),

    _rotateStart: Vector2D = Vector2D.fromZero(),
    _rotateEnd: Vector2D = Vector2D.fromZero(),
    _rotateDelta: Vector2D = Vector2D.fromZero(),

    _panStart: Vector2D = Vector2D.fromZero(),
    _panEnd: Vector2D = Vector2D.fromZero(),
    _panDelta: Vector2D = Vector2D.fromZero(),

    _dollyStart: Vector2D = Vector2D.fromZero(),
    _dollyEnd: Vector2D = Vector2D.fromZero(),
    _dollyDelta: Vector2D = Vector2D.fromZero(),

    _dollyDirection: Vector3D = Vector3D.fromZero(),
    _mouse: Vector2D = Vector2D.fromZero(),
    _performCursorZoom: bool = false,
    enable: bool = true,

    // _pointers = [],
    // _pointerPositions = {},
    _controlActive: bool = false,
    state: _STATE = _STATE.NONE,
    window: *zglfw.Window,

    on_mouse_down_id: u32 = 0,
    on_mouse_up_id: u32 = 0,
    on_mouse_move_id: u32 = 0,
    on_wheel_id: u32 = 0,
    on_mouse_down_enable: bool = true,
    on_mouse_up_enable: bool = false,
    on_mouse_move_enable: bool = false,
    on_wheel_enable: bool = true,

    const Self = @This();
    pub fn new(camera: *Camera, app_backend: *lib.backend.AppBackend) *Self {
        const allocator = lib.mem.getAllocator();
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .camera = camera,
            .window = app_backend.window,
        };
        self.position0 = self.camera.position.clone();
        self.zoom0 = self.camera.zoom;
        self._quat = QuaternionD.fromUnitVectors(&self.camera.up, &Vector3D.new(0, 1, 0));
        self._quatInverse = self._quat.inverse();
        const Closure = struct {
            var this: *OrbitControl = undefined;
            fn onMouseDown(userdata: ?*anyopaque) void {
                if (!this.on_mouse_down_enable) return;
                this.on_mouse_move_enable = true;
                this.on_mouse_up_enable = true;
                const event = @as(*lib.input.MouseEvent, @ptrCast(@alignCast(userdata)));
                switch (event.button) {
                    .left => {
                        //rotate
                        if (event.ctrlKey or event.shiftKey) {
                            if (this.enablePan == false) return;
                            this._handleMouseDownPan(event);
                            this.state = _STATE.PAN;
                        } else {
                            if (this.enableRotate == false) return;
                            this._handleMouseDownRotate(event);
                            this.state = _STATE.ROTATE;
                        }
                    },
                    .middle => {
                        //dolly
                        if (this.enableZoom == false) return;
                        this._handleMouseDownDolly(event);
                        this.state = _STATE.DOLLY;
                    },
                    .right => {
                        //pan
                        if (event.ctrlKey or event.shiftKey) {
                            if (this.enableRotate == false) return;
                            this._handleMouseDownRotate(event);
                            this.state = _STATE.ROTATE;
                        } else {
                            if (this.enablePan == false) return;
                            this._handleMouseDownPan(event);
                            this.state = _STATE.PAN;
                        }
                    },
                    else => {
                        this.state = _STATE.NONE;
                    },
                }
                if (this.state != _STATE.NONE) {
                    this.dispatchEvent("start");
                }
            }
            fn onMouseUp(_: ?*anyopaque) void {
                if (!this.on_mouse_up_enable) return;
                // const event = @as(*lib.input.MouseEvent, @ptrCast(@alignCast(userdata)));
                this.on_mouse_up_enable = false;
                this.on_mouse_move_enable = false;
                this.on_mouse_down_enable = true;
                this.state = _STATE.NONE;
            }
            fn onMouseMove(userdata: ?*anyopaque) void {
                if (!this.on_mouse_move_enable) return;
                const event = @as(*lib.input.MouseMove, @ptrCast(@alignCast(userdata)));
                switch (this.state) {
                    .ROTATE => {
                        if (this.enableRotate == false) return;
                        this._handleMouseMoveRotate(event);
                    },
                    .DOLLY => {
                        if (this.enableZoom == false) return;
                        this._handleMouseMoveDolly(event);
                    },
                    .PAN => {
                        if (this.enablePan == false) return;
                        this._handleMouseMovePan(event);
                    },
                    else => {
                        unreachable;
                    },
                }
            }
            fn onWheel(userdata: ?*anyopaque) void {
                if (!this.on_wheel_enable) return;
                const event = @as(*lib.input.ScrollEvent, @ptrCast(@alignCast(userdata)));
                if (this.enable == false or this.enableZoom == false) return;
                this.dispatchEvent("start");
                this._handleMouseWheel(event);
                this.dispatchEvent("end");
            }
        };
        Closure.this = self;
        self.on_mouse_down_id = lib.input.event.on("mousedown", Closure.onMouseDown);
        self.on_mouse_up_id = lib.input.event.on("mouseup", Closure.onMouseUp);
        self.on_mouse_move_id = lib.input.event.on("mousemove", Closure.onMouseMove);
        self.on_wheel_id = lib.input.event.on("wheel", Closure.onWheel);
        return self;
    }
    pub fn deinit(self: *Self) void {
        _ = lib.input.event.off(self.on_mouse_down_id);
        _ = lib.input.event.off(self.on_mouse_up_id);
        _ = lib.input.event.off(self.on_mouse_move_id);
        _ = lib.input.event.off(self.on_wheel_id);
        lib.mem.getAllocator().destroy(self);
    }
    pub fn update(self: *Self, deltaTime: ?f64) void {
        var targetToPosition = self.camera.position.subtract(&self.target);
        targetToPosition = self._quat.multiplyByPoint(&targetToPosition);
        self._spherical.setFromVector3(&targetToPosition);
        if (self.autoRotate and self.state == _STATE.NONE) {
            self._rotateLeft(self._getAutoRotationAngle(deltaTime));
        }
        if (self.enableDamping) {
            self._spherical.theta += self._sphericalDelta.theta * self.dampingFactor;
            self._spherical.phi += self._sphericalDelta.phi * self.dampingFactor;
        } else {
            self._spherical.theta += self._sphericalDelta.theta;
            self._spherical.phi += self._sphericalDelta.phi;
        }
        var min = self.minAzimuthAngle;
        var max = self.maxAzimuthAngle;
        if (stdmath.isFinite(min) and stdmath.isFinite(max)) {
            if (min < -stdmath.pi) min += stdmath.tau else if (min > stdmath.pi) min -= stdmath.tau;
            if (max < -stdmath.pi) max += stdmath.tau else if (max > stdmath.pi) max -= stdmath.tau;
            if (min <= max) {
                self._spherical.theta = @max(min, @min(max, self._spherical.theta));
            } else {
                self._spherical.theta = if (self._spherical.theta > (min + max) / 2) @max(min, self._spherical.theta) else @min(max, self._spherical.theta);
            }
        }
        // restrict phi to be between desired limits
        self._spherical.phi = @max(self.minPolarAngle, @min(self.maxPolarAngle, self._spherical.phi));
        self._spherical.makeSafe();
        if (self.enableDamping == true) {
            self.target = self._panOffset.multiplyByScalar(self.dampingFactor);
        } else {
            self.target = self.target.add(&self._panOffset);
        }
        self.target = self.target
            .subtract(&self.cursor)
            .clampLength(self.minTargetRadius, self.maxTargetRadius)
            .add(&self.cursor);
        var zoomChanged = false;
        if (self.zoomToCursor and self._performCursorZoom or self.camera.isOrthographicCamera) {
            self._spherical.radius = self._clampDistance(self._spherical.radius);
        } else {
            const prevRadius = self._spherical.radius;
            self._spherical.radius = self._clampDistance(self._spherical.radius * self._scale);
            zoomChanged = prevRadius != self._spherical.radius;
        }
        setFromSpherical(&targetToPosition, &self._spherical);
        targetToPosition = self._quatInverse.multiplyByPoint(&targetToPosition);
        self.camera.position = self.target.add(&targetToPosition);
        // lib.print("{d}\n",.{self.camera.position.length()});
        self.camera.lookAt(&self.target);
        if (self.enableDamping == true) {
            self._sphericalDelta.theta *= 1 - self.dampingFactor;
            self._sphericalDelta.phi *= 1 - self.dampingFactor;
            self._panOffset = self._panOffset.multiplyByScalar(1 - self.dampingFactor);
        } else {
            self._sphericalDelta.set(0, 0, 0);
            self._panOffset = Vector3D.new(0, 0, 0);
        }
        if (self.zoomToCursor and self._performCursorZoom) {
            var newRadius: f64 = 0;
            if (self.camera.isPerspectiveCamera) {
                const prevRadius = targetToPosition.length();
                newRadius = self._clampDistance(prevRadius * self._scale);

                const radiusDelta = prevRadius - newRadius;
                self.camera.position = self.camera.position.addScaledVector(&self._dollyDirection, radiusDelta);
                self.camera.updateMatrixWorld();

                zoomChanged = radiusDelta != 0;
            } else {
                // adjust the ortho camera position based on zoom changes
                const mouseBefore = self.camera.unproject(&self._mouse);

                const prevZoom = self.camera.zoom;
                self.camera.zoom = @max(self.minZoom, @min(self.maxZoom, self.camera.zoom / self._scale));
                self.camera.updateProjection();

                zoomChanged = prevZoom != self.camera.zoom;

                const mouseAfter = self.camera.unproject(&self._mouse);
                self.camera.position = self.camera.position.subtract(&mouseAfter).add(&mouseBefore);
                self.camera.updateMatrixWorld();
                newRadius = targetToPosition.length();
            }

            if (newRadius == 0) {
                if (self.screenSpacePanning) {
                    self.target = self.camera.matrix.transformDirection(&Vector3D.new(0, 0, -1))
                        .multiplyByScalar(newRadius)
                        .add(&self.camera.position);
                } else {}
            }
        } else if (self.camera.isOrthographicCamera) {}
        self._scale = 1;
        self._performCursorZoom = false;
        if (zoomChanged or self._lastPosition.distance2(&self.camera.position) > math.epsilon6 or 8 * (1 - self._lastQuaternion.dot(&self.camera.rotation)) > math.epsilon6 or self._lastTargetPosition.distance2(&self.target) > math.epsilon6) {
            self.dispatchEvent("changeEvent");
            self._lastPosition = self.camera.position.clone();
            self._lastQuaternion = self.camera.rotation.clone();
            self._lastTargetPosition = self.target.clone();
        }
        self.camera.updateMatrix();
        // self.camera.position.print();
    }
    pub fn setFromSpherical(v: *Vector3D, s: *const Spherical) void {
        const sinPhiRadius = stdmath.sin(s.phi) * s.radius;
        v.v[0] = sinPhiRadius * stdmath.sin(s.theta);
        v.v[1] = stdmath.cos(s.phi) * s.radius;
        v.v[2] = sinPhiRadius * stdmath.cos(s.theta);
    }
    pub fn _clampDistance(self: *const Self, distance: f64) f64 {
        return @max(self.minDistance, @min(self.maxDistance, distance));
    }
    pub fn getDistance(self: *const Self) f64 {
        return self.camera.position.distance(self.target);
    }
    pub fn getPolarAngle(self: *const Self) f64 {
        return self._spherical.phi;
    }
    pub fn _getAutoRotationAngle(self: *const Self, deltaTime: ?f64) f64 {
        if (deltaTime) |t| {
            return (stdmath.tau / 60.0 * self.autoRotateSpeed) * t;
        } else {
            return stdmath.tau / 60.0 * self.autoRotateSpeed;
        }
    }
    pub fn getAzimuthalAngle(self: *const Self) f64 {
        return self._spherical.theta;
    }
    fn dispatchEvent(self: *Self, _: []const u8) void {
        _ = self;
        // lib.print("{s}\n", .{name});
    }
    fn _handleMouseDownPan(self: *Self, event: *lib.input.MouseEvent) void {
        self._panStart.setX(event.clientX);
        self._panStart.setY(event.clientY);
    }
    fn _handleMouseDownRotate(self: *Self, event: *lib.input.MouseEvent) void {
        self._rotateStart.setX(event.clientX);
        self._rotateStart.setY(event.clientY);
    }
    fn _handleMouseDownDolly(self: *Self, event: *lib.input.MouseEvent) void {
        self._updateZoomParameters(event.clientX, event.clientX);
        self._dollyStart.setX(event.clientX);
        self._dollyStart.setY(event.clientY);
    }
    fn _updateZoomParameters(self: *Self, x: f64, y: f64) void {
        if (!self.zoomToCursor) return;
        self._performCursorZoom = true;
        const size = self.getWindowSize();
        const pos = self.getWindowPos();
        const dx = x - pos[0];
        const dy = y - pos[1];
        const w = size[0];
        const h = size[1];
        self._mouse.setX((dx / w) * 2 - 1);
        self._mouse.setY((dy / h) * 2 - 1);

        self._dollyDirection.setX(self._mouse.x());
        self._dollyDirection.setY(self._mouse.y());
        self._dollyDirection = self.camera.projection_matrix.multiply(&self.camera.view_matrix).multiplyByPoint(&self._dollyDirection).subtract(&self.camera.position).normalize();
    }
    ///get size of window
    fn getWindowSize(self: *Self) [2]f64 {
        const size = self.window.getSize();
        return .{ @floatFromInt(size[0]), @floatFromInt(size[1]) };
    }
    ///get left and top corner of window
    fn getWindowPos(self: *Self) [2]f64 {
        const pos = self.window.getPos();
        return .{ @floatFromInt(pos[0]), @floatFromInt(pos[1]) };
    }
    fn _handleMouseWheel(self: *Self, event: *lib.input.ScrollEvent) void {
        event.yoffset *= -100; //前端向上滚动滚轮后的deltaY是-100，zglfw中是1,所以这里乘以-100来暂时适配框架内。TODO 需要优化。
        const yoffset = event.yoffset * 16;
        self._updateZoomParameters(event.xoffset, event.yoffset);
        if (yoffset < 0) {
            self._dollyIn(self._getZoomScale(yoffset));
        } else if (yoffset > 0) {
            self._dollyOut(self._getZoomScale(yoffset));
        }
        self.update(null);
    }
    fn _handleMouseMoveRotate(self: *Self, event: *lib.input.MouseMove) void {
        self._rotateEnd.setX(event.clientX);
        self._rotateEnd.setY(event.clientY);
        self._rotateDelta = self._rotateEnd.subtract(&self._rotateStart).multiplyByScalar(self.rotateSpeed);
        const size = self.getWindowSize();
        self._rotateLeft(stdmath.tau * self._rotateDelta.x() / size[0]);
        self._rotateUp(stdmath.tau * self._rotateDelta.y() / size[1]);
        self._rotateStart = self._rotateEnd.clone();
        self.update(null);
    }
    fn _handleMouseMoveDolly(self: *Self, event: *lib.input.MouseMove) void {
        self._dollyEnd.setX(event.clientX);
        self._dollyEnd.setY(event.clientY);
        self._dollyDelta = self._dollyEnd.subtract(&self._dollyStart);
        if (self._dollyDelta.y() > 0) {
            self._dollyOut(self._getZoomScale(self._dollyDelta.y()));
        } else {
            self._dollyIn(self._getZoomScale(self._dollyDelta.y()));
        }
        self._dollyStart = self._dollyEnd.clone();
        self.update(null);
    }
    fn _handleMouseMovePan(self: *Self, event: *lib.input.MouseMove) void {
        self._panEnd.setX(event.clientX);
        self._panEnd.setY(event.clientY);
        self._panDelta = self._panEnd.subtract(&self._panStart).multiplyByScalar(self.panSpeed);
        self._pan(self._panDelta.x(), self._panDelta.y());
        self._panStart = self._panEnd.clone();
        self.update(null);
    }
    fn _rotateLeft(self: *Self, angle: f64) void {
        self._sphericalDelta.theta -= angle;
    }
    fn _rotateUp(self: *Self, angle: f64) void {
        self._sphericalDelta.phi -= angle;
    }
    fn _dollyOut(self: *Self, dollyScale: f64) void {
        self._scale /= dollyScale;
    }
    fn _dollyIn(self: *Self, dollyScale: f64) void {
        self._scale *= dollyScale;
    }
    fn _getZoomScale(self: *Self, delta: f64) f64 {
        const normalizedDelta = @abs(delta * 0.01);
        return stdmath.pow(f64, 0.95, self.zoomSpeed * normalizedDelta);
    }
    fn _panLeft(self: *Self, distance: f64, objectMatrix: Mat4) void {
        const v = objectMatrix.getColVector3(0);
        self._panOffset = self._panOffset.add(&v.multiplyByScalar(-distance));
    }
    fn _panUp(self: *Self, distance: f64, objectMatrix: Mat4) void {
        var _v: Vector3D = undefined;
        if (self.screenSpacePanning == true) {
            _v = objectMatrix.getColVector3(1);
        } else {
            _v = objectMatrix.getColVector3(0);
            _v = self.camera.up.cross(&_v);
        }
        self._panOffset = self._panOffset.add(&_v.multiplyByScalar(-distance));
    }
    fn _pan(self: *Self, deltaX: f64, deltaY: f64) void {
        if (self.camera.isPerspectiveCamera) {
            const _v = self.camera.position.subtract(&self.target);
            const targetDistance = _v.length() * stdmath.tan(self.camera.fovy / 2);
            const size = self.getWindowSize();
            self._panLeft(2 * deltaX * targetDistance / size[0], self.camera.matrix_world);
            self._panUp(2 * deltaY * targetDistance / size[1], self.camera.matrix_world);
        } else if (self.camera.isOrthographicCamera) {
            // const size = self.getWindowSize();
            // self._panLeft(deltaX * (self.camera.right - self.camera.left) / self.camera.zoom / size[0], self.camera.matrix);
            // self._panUp(deltaY * (self.camera.top - self.camera.bottom) / self.camera.zoom / size[1], self.camera.matrix);
        }
    }
    pub fn modAngle32(in_angle: f64) f64 {
        const angle = in_angle + stdmath.pi;
        var temp: f64 = @abs(angle);
        temp = temp - (2.0 * stdmath.pi * @as(f64, @floatFromInt(@as(i32, @intFromFloat(temp / stdmath.pi)))));
        temp = temp - stdmath.pi;
        if (angle < 0.0) {
            temp = -temp;
        }
        return temp;
    }
};

// module
var control: *OrbitControl = undefined;
pub fn setCamera(camera: *Camera, app_backend: *lib.backend.AppBackend) void {
    control = OrbitControl.new(camera, app_backend);
}

pub fn module() modules.Module {
    const inputSubsystem = modules.Module{
        .name = "camera-control",
        .pre_draw_fn = on_update,
        .cleanup_fn = on_deinit,
    };
    return inputSubsystem;
}
pub fn on_update(_: *backend.AppBackend) void {
    // control.update(null);
}
pub fn on_deinit() !void {
    control.deinit();
}
