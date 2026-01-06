import React, { useRef, useEffect } from "react";
import PencilIcon from "./PencilIcon";
import "./YellowPad.css";

interface YellowPadProps {
  content: string;
  onContentChange: (content: string) => void;
  isRecording: boolean;
}

const YellowPad: React.FC<YellowPadProps> = ({
  content,
  onContentChange,
  isRecording,
}) => {
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const pencilRef = useRef<HTMLDivElement>(null);

  // Update pencil position based on cursor
  useEffect(() => {
    const updatePencilPosition = () => {
      if (!textareaRef.current || !pencilRef.current) return;

      const textarea = textareaRef.current;
      const pencil = pencilRef.current;

      // Create a mirror div to calculate text dimensions
      const mirror = document.createElement("div");
      mirror.style.cssText = `
        position: absolute;
        visibility: hidden;
        white-space: pre-wrap;
        word-wrap: break-word;
        font-family: 'Poor Story', cursive;
        font-size: 1.25rem;
        line-height: 2rem;
        padding: 1rem;
        width: ${textarea.clientWidth}px;
      `;
      mirror.textContent = content || " ";
      document.body.appendChild(mirror);

      const lines = mirror.clientHeight / 32; // 2rem = 32px
      const lastLineWidth = getLastLineWidth(mirror, content);

      document.body.removeChild(mirror);

      // Position pencil at end of text
      const top = Math.max(0, (lines - 1) * 32) + 16;
      const left = Math.min(lastLineWidth + 24, textarea.clientWidth - 40);

      pencil.style.top = `${top}px`;
      pencil.style.left = `${left}px`;
      pencil.style.opacity = content ? "1" : "0.5";
    };

    updatePencilPosition();
  }, [content]);

  const getLastLineWidth = (
    mirror: HTMLDivElement,
    text: string
  ): number => {
    const lines = text.split("\n");
    const lastLine = lines[lines.length - 1] || "";

    const span = document.createElement("span");
    span.style.cssText = `
      font-family: 'Poor Story', cursive;
      font-size: 1.25rem;
      visibility: hidden;
      white-space: pre;
    `;
    span.textContent = lastLine;
    document.body.appendChild(span);
    const width = span.offsetWidth;
    document.body.removeChild(span);

    return width + 16; // padding
  };

  return (
    <div className="yellow-pad">
      {/* Red margin line */}
      <div className="red-margin" />

      {/* Blue horizontal lines */}
      <div className="blue-lines">
        {Array.from({ length: 20 }).map((_, i) => (
          <div key={i} className="blue-line" />
        ))}
      </div>

      {/* Text area */}
      <textarea
        ref={textareaRef}
        className="pad-textarea"
        value={content}
        onChange={(e) => onContentChange(e.target.value)}
        placeholder="여기에 받아쓰기 내용이 표시됩니다..."
        spellCheck={false}
      />

      {/* Floating pencil */}
      <div ref={pencilRef} className="floating-pencil">
        <PencilIcon className={isRecording ? "pencil-writing" : ""} />
      </div>
    </div>
  );
};

export default YellowPad;


