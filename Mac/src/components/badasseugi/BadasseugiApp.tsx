import React, { useState, useEffect, useCallback } from "react";
import { listen } from "@tauri-apps/api/event";
import BadasseugiSidebar from "./BadasseugiSidebar";
import YellowPad from "./YellowPad";
import RecordButton from "./RecordButton";
import { commands } from "@/bindings";
import "./BadasseugiApp.css";

interface BadasseugiAppProps {
  onSettingsClick?: () => void;
}

const BadasseugiApp: React.FC<BadasseugiAppProps> = ({ onSettingsClick }) => {
  const [isRecording, setIsRecording] = useState(false);
  const [content, setContent] = useState("");
  const [activeMenuItem, setActiveMenuItem] = useState("notebook");

  // Debug: 컴포넌트가 마운트되었는지 확인
  useEffect(() => {
    console.log("🎨 BadasseugiApp mounted!");
  }, []);

  // Listen for recording state changes from Tauri backend
  useEffect(() => {
    let unlistenShow: (() => void) | null = null;
    let unlistenHide: (() => void) | null = null;
    let unlistenTranscription: (() => void) | null = null;

    const setupListeners = async () => {
      console.log("🎤 이벤트 리스너 설정 중...");
      
      // Listen for overlay show (recording started)
      unlistenShow = await listen("show-overlay", (event) => {
        console.log("📢 show-overlay 이벤트 수신:", event.payload);
        const state = event.payload as string;
        if (state === "recording") {
          console.log("✅ 녹음 시작됨!");
          setIsRecording(true);
        }
      });

      // Listen for overlay hide (recording stopped)
      unlistenHide = await listen("hide-overlay", () => {
        console.log("⏹️ hide-overlay 이벤트 수신 - 녹음 중지");
        setIsRecording(false);
      });

      // Listen for transcription results
      unlistenTranscription = await listen<string>("transcription-result", (event) => {
        console.log("📝 받아쓰기 결과 수신:", event.payload);
        const transcribedText = event.payload;
        setContent((prev) => prev + (prev ? "\n" : "") + transcribedText);
      });

      // Check initial recording state
      try {
        const recording = await commands.isRecording();
        console.log("🔍 초기 녹음 상태:", recording);
        setIsRecording(recording);
      } catch (error) {
        console.error("❌ 녹음 상태 확인 실패:", error);
      }
      
      console.log("✅ 모든 이벤트 리스너 설정 완료!");
    };

    setupListeners();

    return () => {
      if (unlistenShow) unlistenShow();
      if (unlistenHide) unlistenHide();
      if (unlistenTranscription) unlistenTranscription();
    };
  }, []);

  const handleToggleRecording = useCallback(async () => {
    try {
      // 녹음은 글로벌 단축키(Ctrl+Shift+Space)를 통해 트리거됩니다
      const currentRecording = await commands.isRecording();
      console.log("🔘 녹음 버튼 클릭 - 현재 상태:", currentRecording);
      
      if (!currentRecording) {
        // 녹음이 시작되지 않은 경우, 사용자에게 단축키 사용 안내
        const message = `🎤 녹음을 시작하려면\n\n${shortcutHint}\n\n키를 누르세요.\n\n(앱이 포커스되지 않아도 작동합니다)`;
        alert(message);
      } else {
        // 녹음 중인 경우, 취소 안내
        alert("⏹️ 녹음 중입니다.\n\n중지하려면 취소 단축키를 누르거나,\n다시 녹음 단축키를 눌러주세요.");
      }
    } catch (error) {
      console.error("❌ 녹음 상태 확인 실패:", error);
      alert("오류가 발생했습니다. 콘솔을 확인하세요.");
    }
  }, []);

  const handleMenuItemClick = (id: string) => {
    if (id === "new") {
      // Clear content for new dictation
      setContent("");
    }
    setActiveMenuItem(id);
  };

  const handleSettingsClick = () => {
    // You can implement settings modal or navigate to settings page here
    console.log("Settings clicked - implement settings modal");
  };

  // Determine shortcut based on platform
  const isMac = navigator.platform.toUpperCase().indexOf("MAC") >= 0;
  const shortcutHint = isMac ? "⌘+Shift+Space" : "Ctrl+Shift+Space";

  return (
    <div className="badasseugi-app">
      {/* Left Sidebar */}
      <BadasseugiSidebar
        activeItem={activeMenuItem}
        onItemClick={handleMenuItemClick}
        onSettingsClick={onSettingsClick || handleSettingsClick}
      />

      {/* Main Content Area */}
      <main className="badasseugi-main">
        {/* Yellow Pad (notepad area) */}
        <div className="pad-container">
          <YellowPad
            content={content}
            onContentChange={setContent}
            isRecording={isRecording}
          />
        </div>

        {/* Bottom Recording Controls */}
        <footer className="recording-controls">
          <RecordButton
            isRecording={isRecording}
            onToggleRecording={handleToggleRecording}
            shortcutHint={shortcutHint}
          />
        </footer>
      </main>
    </div>
  );
};

export default BadasseugiApp;

