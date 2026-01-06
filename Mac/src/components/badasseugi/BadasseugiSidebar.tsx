import React from "react";
import { Plus, Book, Star, Trash2, Settings } from "lucide-react";
import "./BadasseugiSidebar.css";

interface MenuItem {
  id: string;
  icon: React.ReactNode;
  label: string;
  onClick?: () => void;
}

interface BadasseugiSidebarProps {
  activeItem?: string;
  onItemClick?: (id: string) => void;
  onSettingsClick?: () => void;
}

const BadasseugiSidebar: React.FC<BadasseugiSidebarProps> = ({
  activeItem = "notebook",
  onItemClick,
  onSettingsClick,
}) => {
  const menuItems: MenuItem[] = [
    {
      id: "new",
      icon: <Plus size={20} />,
      label: "+ 새 받아쓰기",
    },
    {
      id: "notebook",
      icon: <Book size={20} />,
      label: "내 공책",
    },
    {
      id: "important",
      icon: <Star size={20} />,
      label: "중요한 기록",
    },
    {
      id: "trash",
      icon: <Trash2 size={20} />,
      label: "휴지통",
    },
  ];

  return (
    <div className="badasseugi-sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="logo-icon">📝</div>
        <h1 className="logo-text">받아쓰기</h1>
      </div>

      {/* Menu Items */}
      <nav className="sidebar-nav">
        {menuItems.map((item) => (
          <button
            key={item.id}
            className={`sidebar-item ${activeItem === item.id ? "active" : ""}`}
            onClick={() => onItemClick?.(item.id)}
          >
            <span className="item-icon">{item.icon}</span>
            <span className="item-label">{item.label}</span>
          </button>
        ))}
      </nav>

      {/* Spacer */}
      <div className="sidebar-spacer" />

      {/* Settings */}
      <button className="sidebar-item settings-item" onClick={onSettingsClick}>
        <span className="item-icon">
          <Settings size={20} />
        </span>
        <span className="item-label">설정</span>
      </button>
    </div>
  );
};

export default BadasseugiSidebar;


