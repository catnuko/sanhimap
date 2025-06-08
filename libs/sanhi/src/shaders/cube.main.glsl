@include src/shaders/header.glsl

@vs vs
@include src/shaders/common_vs.glsl

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;
void main(){
  gl_Position = mvp * vec4(position,1.0);
}

@end

@fs fs
out vec4 frag_color;

void main() {
  frag_color = vec4(1.0,0.0,0.0,1.0);
}
@end

@program cube vs fs