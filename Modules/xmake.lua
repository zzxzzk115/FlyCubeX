includes("AppSettings")
includes("AppLoop")

if not is_plat("ios") and not is_plat("tvos") then
    includes("AppBox")
end