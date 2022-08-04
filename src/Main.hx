package;

import js.Browser.window;
import js.Browser.document;

import js.html.webgl.WebGL2RenderingContext as WebGL;


class Main {
    static function main() {
        window.onload = ()->new Main();
    }

    public function new() {
        var canvas:js.html.CanvasElement = cast document.getElementById("c");
        canvas.width = canvas.height = 1024;
        var twgl:Dynamic = untyped window.twgl;
        var m4:Dynamic = untyped twgl.m4;
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
        var uniforms = {
            u_lightWorldPos: [1, 8, -10],
            u_lightColor: [1, 0.8, 0.8, 1],
            u_ambient: [0, 0, 0, 1],
            u_specular: [1, 1, 1, 1],
            u_shininess: 50,
            u_specularFactor: 1,
            u_diffuse: tex,
            u_diffuse2: tex2,
            u_viewInverse: null,
            u_world: null,
            u_worldViewProjection: null,
            u_worldInverseTranspose: null,
        };
        function render(time:Float) {
            time *= 0.001;
            twgl.resizeCanvasToDisplaySize(gl.canvas);
            gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
            gl.enable(WebGL.DEPTH_TEST);
            gl.enable(WebGL.CULL_FACE);
            gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
            var fov = 40 * Math.PI / 180;
            var aspect = gl.canvas.clientWidth / gl.canvas.clientHeight;
            var zNear = 0.1;
            var zFar = 1000;
            var projection = m4.perspective(fov, aspect, zNear, zFar);
            var eye = [1, 4, -6];
            var target = [0, 0, 0];
            var up = [0, 1, 0];
            var camera = m4.lookAt(eye, target, up);
            var view = m4.inverse(camera);
            var viewProjection = m4.multiply(projection, view);
            var world = m4.rotationY(time);
            uniforms.u_viewInverse = camera;
            uniforms.u_world = world;
            uniforms.u_worldInverseTranspose = m4.transpose(m4.inverse(world));
            uniforms.u_worldViewProjection = m4.multiply(viewProjection, world);
            gl.useProgram(programInfo.program);
            twgl.setBuffersAndAttributes(gl, programInfo, bufferInfo);
            twgl.setUniforms(programInfo, uniforms);
            gl.drawElements(WebGL.TRIANGLES, bufferInfo.numElements, WebGL.UNSIGNED_SHORT, 0);
            js.Browser.window.requestAnimationFrame(render);
        }
        js.Browser.window.requestAnimationFrame(render);
    }
}
