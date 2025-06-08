# 遍历 src/shaders/ 下所有 .glsl 文件
for input in src/shaders/*.main.glsl; do
    output="${input%.glsl}.zig"  # 替换 .glsl 为 .zig
    echo "Compiling $input → $output"
    ./sokol-shdc -i "$input" -o "$output" -l wgsl:glsl430:glsl310es:hlsl5 -f sokol_zig
done
read -p "编译完成，按 Enter 键退出..."s