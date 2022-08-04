package;

import js.Browser.window;
import js.Browser.document;

import js.html.webgl.WebGL2RenderingContext as WebGL;

abstract Point(Array<Float>) from Array<Float> to Array<Float> {
    public function new(x, y, z) {
        this = [x, y, z];
    }
    public var x(get, set):Float;
    inline function get_x() return this[0];
    inline function set_x(value) return this[0] = value;
    public var y(get, set):Float;
    inline function get_y() return this[1];
    inline function set_y(value) return this[1] = value;
    public var z(get, set):Float;
    inline function get_z() return this[2];
    inline function set_z(value) return this[2] = value;

    @:op(A * B)
    @:commutative
    inline static public function mulOp(a:Point, b:Float) {
        return new Point(a.x * b, a.y * b, a.z * b);
    }

    @:op(A / B)
    @:commutative
    inline static public function divOp(a:Point, b:Float) {
        return new Point(a.x / b, a.y / b, a.z / b);
    }

    @:op(A + B)
    inline static public function addOp(a:Point, b:Point) {
        return new Point(a.x + b.x, a.y + b.y, a.z + b.z);
    }

    @:op(A - B)
    inline static public function minOp(a:Point, b:Point) {
        return new Point(a.x - b.x, a.y - b.y, a.z - b.z);
    }

    public function getLength() : Float{
        return Math.sqrt(this[0] * this[0] + this[1] * this[1] + this[2] * this[2]);
    }

    public function getSquareLength() : Float{
        return this[0] * this[0] + this[1] * this[1] + this[2] * this[2];
    }
    public function copyFrom(other:Point) {
        this[0] = other[0]; this[1] = other[1]; this[2] = other[2];
    }
}


var twgl:Dynamic = untyped window.twgl;
var m4:Dynamic = untyped window.twgl.m4;

class Camera {
    public var matrix:Dynamic;
    public var pitch:Float = -0.2;
    public var yaw:Float = 3.14;
    public var position = new Point(0, 2, -6);
    public function new() {
        matrix = m4.identity();
    }

    public function update() {
        m4.identity(matrix);
        m4.setTranslation(matrix, position, matrix);
        m4.rotateY(matrix, yaw, matrix);
        m4.rotateX(matrix, pitch, matrix);
    }
}

class World {
    public var map:Map<Int, Map<Int, Map<Int, Bool>>> = new Map<Int, Map<Int, Map<Int, Bool>>>();

    public function new() {
        /* set(0, 0, 0); */
        for(i in 0...10) {
            var x = Std.random(20) - 10;
            var y = Std.random(5);
            var z = Std.random(10) - 5;
            set(x, y, z);
        }
    }

    public function set(x, y, z) {
        if(map[x] == null) {
            map[x] = new Map<Int, Map<Int, Bool>>();
        }

        if(map[x][y] == null) {
            map[x][y] = new Map<Int, Bool>();
        }

        map[x][y][z] = true;
    }
}

class Main {
    static function main() {
        window.onload = ()->new Main();
    }

    var camera = new Camera();
    var mouse = new Point(0, 0, 0);
    var previousMouse = new Point(0, 0, 0);

    var world = new World();

    var keys:Dynamic = {};

    function new() {
        var canvas:js.html.CanvasElement = cast document.getElementById("c");
        canvas.width = canvas.height = 1024;
        canvas.onmousemove = canvas.onmousedown = canvas.onmouseup = onMouseMove;
        canvas.onmouseenter = function(e) {
            /* previousMouse.x = e.clientX; */
            /* previousMouse.y = e.clientY; */
        }
        untyped onkeydown = onkeyup = function(e) {
            keys[e.key] = e.type[3] == 'd';
        }
        canvas.oncontextmenu = e->false;
        var gl:js.html.webgl.WebGL2RenderingContext = canvas.getContext("webgl");
        var programInfo = twgl.createProgramInfo(gl, ["vs", "fs"]);
        var arrays = {
            position: [1, 1, -1, 1, 1, 1, 1, -1, 1, 1, -1, -1, -1, 1, 1, -1, 1, -1, -1, -1, -1, -1, -1, 1, -1, 1, 1, 1, 1, 1, 1, 1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1, 1, -1, 1, -1, -1, 1, 1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, -1, 1, 1, -1, 1, -1, -1, -1, -1, -1],
            normal:   [1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1],
            texcoord: [1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1],
            indices:  [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 8, 10, 11, 12, 13, 14, 12, 14, 15, 16, 17, 18, 16, 18, 19, 20, 21, 22, 20, 22, 23],
        };
        var bufferInfo = twgl.createBufferInfoFromArrays(gl, arrays);
        var tex = twgl.createTexture(gl, {
            min: WebGL.NEAREST,
            mag: WebGL.NEAREST,
            src: "../data/dirt_grass.png"
        });
        var tex2 = twgl.createTexture(gl, {
            min: WebGL.NEAREST,
            mag: WebGL.NEAREST,
            src: "../data/grass_top.png"
        });
        var tex3 = twgl.createTexture(gl, {
            min: WebGL.NEAREST,
            mag: WebGL.NEAREST,
            src: "../data/dirt.png"
        });
        var uniforms = {
            u_lightWorldPos: [1, 80, -10],
            u_lightColor: [1, 0.8, 0.8, 1],
            u_ambient: [0.3, 0.3, 0.3, 1],
            u_specular: [1, 1, 1, 1],
            u_shininess: 50,
            u_specularFactor: 1,
            u_diffuse: tex,
            u_diffuse2: tex2,
            u_diffuse3: tex3,
            u_viewInverse: null,
            u_world: null,
            u_worldViewProjection: null,
            u_worldInverseTranspose: null,
        };
        function render(time:Float) {
            twgl.resizeCanvasToDisplaySize(gl.canvas);
            gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
            gl.enable(WebGL.DEPTH_TEST);
            gl.enable(WebGL.CULL_FACE);
            gl.clearColor(0.52, 0.80, 0.92, 1.0);
            gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
            var fov = 60 * Math.PI / 180;
            var aspect = gl.canvas.clientWidth / gl.canvas.clientHeight;
            var zNear = 0.1;
            var zFar = 1000;
            var projection = m4.perspective(fov, aspect, zNear, zFar);
            var view = m4.inverse(camera.matrix);
            var viewProjection = m4.multiply(projection, view);
            gl.useProgram(programInfo.program);
            twgl.setBuffersAndAttributes(gl, programInfo, bufferInfo);
            var s = 1;

            for(x => mapx in world.map) {
                for(y => mapy in mapx) {
                    for(z=> value in mapy) {
                        var world = m4.translation([x*s, y*z, z*s]);
                        uniforms.u_viewInverse = camera.matrix;
                        uniforms.u_world = world;
                        uniforms.u_worldInverseTranspose = m4.transpose(m4.inverse(world));
                        uniforms.u_worldViewProjection = m4.multiply(viewProjection, world);
                        twgl.setUniforms(programInfo, uniforms);
                        gl.drawElements(WebGL.TRIANGLES, bufferInfo.numElements, WebGL.UNSIGNED_SHORT, 0);
                    }
                }
            }
        }
        function loop(time:Float) {
            processControls();
            camera.update();
            render(time);
            js.Browser.window.requestAnimationFrame(loop);
        }
        js.Browser.window.requestAnimationFrame(loop);
    }

    function onMouseMove(e) {
        if(e.buttons == 2) {
            mouse.x = e.clientX;
            mouse.y = e.clientY;
        } else {
            mouse.x = e.clientX;
            mouse.y = e.clientY;
            previousMouse.x = e.clientX;
            previousMouse.y = e.clientY;
        }
    }

    function processControls() {
        var sensitivity = 0.01;
        var speed = 0.15;
        var deltaMouse = mouse - previousMouse;
        camera.yaw -= deltaMouse.x * sensitivity;
        camera.pitch -= deltaMouse.y * sensitivity;
        previousMouse.copyFrom(mouse);
        var direction:Point = m4.getAxis(camera.matrix, 2);
        var lateral_direction:Point = m4.getAxis(camera.matrix, 0);

        if(untyped keys['w']) {
            camera.position -= direction * 0.15;
        }

        if(untyped keys['s']) {
            camera.position += direction * 0.15;
        }

        if(untyped keys['a']) {
            camera.position -= lateral_direction * 0.15;
        }

        if(untyped keys['d']) {
            camera.position += lateral_direction * 0.15;
        }
    }

}
