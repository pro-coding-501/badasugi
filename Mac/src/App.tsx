import { useEffect, useState } from "react";
import { Toaster } from "sonner";
import "./App.css";
import Onboarding from "./components/onboarding";
import { BadasseugiApp } from "./components/badasseugi";
import { Sidebar, SidebarSection, SECTIONS_CONFIG } from "./components/Sidebar";
import AccessibilityPermissions from "./components/AccessibilityPermissions";
import Footer from "./components/footer";
import { commands } from "@/bindings";

type AppView = "badasseugi" | "settings";

const renderSettingsContent = (section: SidebarSection) => {
  const ActiveComponent =
    SECTIONS_CONFIG[section]?.component || SECTIONS_CONFIG.general.component;
  return <ActiveComponent />;
};

function App() {
  const [showOnboarding, setShowOnboarding] = useState<boolean | null>(null);
  const [currentView, setCurrentView] = useState<AppView>("badasseugi");
  const [currentSection, setCurrentSection] = useState<SidebarSection>("general");

  useEffect(() => {
    checkOnboardingStatus();
  }, []);

  // ESC 키로 설정에서 받아쓰기로 복귀
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" && currentView === "settings") {
        setCurrentView("badasseugi");
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [currentView]);

  const checkOnboardingStatus = async () => {
    try {
      const result = await commands.hasAnyModelsAvailable();
      if (result.status === "ok") {
        setShowOnboarding(!result.data);
      } else {
        setShowOnboarding(true);
      }
    } catch (error) {
      console.error("Failed to check onboarding status:", error);
      setShowOnboarding(true);
    }
  };

  const handleModelSelected = () => {
    setShowOnboarding(false);
  };

  const handleSettingsClick = () => {
    setCurrentView("settings");
  };

  const handleBackToBadasseugi = () => {
    setCurrentView("badasseugi");
  };

  // 온보딩 화면
  if (showOnboarding) {
    return <Onboarding onModelSelected={handleModelSelected} />;
  }

  // 받아쓰기 메인 화면
  if (currentView === "badasseugi") {
    console.log("📝 Rendering BadasseugiApp view");
    return (
      <div style={{ width: "100vw", height: "100vh", position: "fixed", top: 0, left: 0 }}>
        <Toaster />
        <BadasseugiApp onSettingsClick={handleSettingsClick} />
      </div>
    );
  }

  // 설정 화면 (기존 Handy UI)
  return (
    <div className="h-screen flex flex-col">
      <Toaster />
      {/* 받아쓰기로 돌아가기 버튼 */}
      <button
        onClick={handleBackToBadasseugi}
        style={{ fontFamily: "'Poor Story', cursive" }}
        className="fixed top-4 left-4 z-50 flex items-center gap-2 px-4 py-2 bg-white/90 backdrop-blur-sm rounded-lg shadow-md hover:bg-white transition-colors"
      >
        <span>←</span>
        <span>받아쓰기로 돌아가기</span>
      </button>
      <div className="flex-1 flex overflow-hidden">
        <Sidebar
          activeSection={currentSection}
          onSectionChange={setCurrentSection}
        />
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="flex-1 overflow-y-auto">
            <div className="flex flex-col items-center p-4 gap-4">
              <AccessibilityPermissions />
              {renderSettingsContent(currentSection)}
            </div>
          </div>
        </div>
      </div>
      <Footer />
    </div>
  );
}

export default App;
