@echo off
cd /d "C:\Users\lenovo\Documents\tutor-platform"
echo 🚀 优学帮 - 一键部署
echo ====================
echo.
echo 📝 提交代码...
"C:\Program Files\Git\bin\git.exe" add -A
"C:\Program Files\Git\bin\git.exe" commit -m "更新：%date% %time%"
echo.
echo 📤 推送到 GitHub...
"C:\Program Files\Git\bin\git.exe" push origin master
echo.
echo 📦 触发 Netlify 部署...
curl -s -X POST "https://api.netlify.com/build_hooks/6a48e4417c5c2f728c6d8d49" > nul 2>&1
echo ✅ 完成！稍后访问 https://youxuebang.netlify.app 查看更新
pause
