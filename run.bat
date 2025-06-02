@echo off

echo Setting up backend...
cd backend
call npm install
start "" cmd /k "npm start"

cd ..
echo Setting up frontend...
cd frontend
call npm install
call npm run dev
