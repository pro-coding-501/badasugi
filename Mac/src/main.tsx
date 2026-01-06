import React from "react";
import ReactDOM from "react-dom/client";
import { BadasseugiApp } from "./components/badasseugi";
import "./App.css";

// 개발자 도구 강제 활성화
window.addEventListener('keydown', (e) => {
  if (e.key === 'F12' || (e.ctrlKey && e.shiftKey && e.key === 'I')) {
    e.stopPropagation();
    e.preventDefault();
  }
}, true);

window.addEventListener('contextmenu', (e) => {
  e.stopPropagation();
}, true);

console.log("🚀 받아쓰기 앱 시작! - BadasseugiApp 렌더링");

const rootElement = document.getElementById("root");
if (!rootElement) {
  throw new Error("Root element not found!");
}

ReactDOM.createRoot(rootElement).render(
  <React.StrictMode>
    <BadasseugiApp />
  </React.StrictMode>
);
