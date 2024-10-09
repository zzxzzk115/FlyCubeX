#version 450

layout(location = 0) in vec4 inPos;

layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 0) uniform Settings {
    vec4 color;
};

void main() {
    outColor = color;
}
