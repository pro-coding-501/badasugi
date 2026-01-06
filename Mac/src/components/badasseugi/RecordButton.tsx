import React from "react";
import { Mic, Square } from "lucide-react";
import AudioVisualizer from "./AudioVisualizer";
import "./RecordButton.css";

interface RecordButtonProps {
  isRecording: boolean;
  onToggleRecording: () => void;
  shortcutHint?: string;
}

const RecordButton: React.FC<RecordButtonProps> = ({
  isRecording,
  onToggleRecording,
  shortcutHint = "⌘+Shift+Space",
}) => {
  return (
    <div className="record-button-container">
      <button
        className={`record-button ${isRecording ? "recording" : ""}`}
        onClick={onToggleRecording}
        aria-label={isRecording ? "녹음 중지" : "녹음 시작"}
      >
        <div className="button-content">
          {isRecording ? (
            <>
              <AudioVisualizer isRecording={isRecording} barCount={6} />
              <Square className="stop-icon" size={16} />
            </>
          ) : (
            <>
              <Mic className="mic-icon" size={24} />
              <span className="button-text">녹음</span>
            </>
          )}
        </div>

        {/* Ripple effect when recording */}
        {isRecording && (
          <>
            <span className="ripple ripple-1" />
            <span className="ripple ripple-2" />
            <span className="ripple ripple-3" />
          </>
        )}
      </button>

      {/* Shortcut hint */}
      <div className="shortcut-hint">
        <kbd>{shortcutHint}</kbd>
      </div>
    </div>
  );
};

export default RecordButton;


