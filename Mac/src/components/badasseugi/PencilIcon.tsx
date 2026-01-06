import React from "react";

interface PencilIconProps {
  className?: string;
  width?: number;
  height?: number;
}

const PencilIcon: React.FC<PencilIconProps> = ({
  className = "",
  width = 64,
  height = 64,
}) => {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 64 64"
      width={width}
      height={height}
      className={className}
    >
      {/* Pink eraser */}
      <path
        fill="#F48FB1"
        d="M56.6 16.5c2.2-2.2 2.2-5.7 0-7.9 -2.2-2.2-5.7-2.2-7.9 0L42 15.3l7.9 7.9L56.6 16.5z"
      />
      {/* Metal ferrule */}
      <path
        fill="#BDBDBD"
        d="M42 15.3l-3.9-3.9c-0.6-0.6-1.5-0.6-2.1 0l-2 2c-0.6 0.6-0.6 1.5 0 2.1l3.9 3.9L42 15.3z"
      />
      {/* Yellow pencil body */}
      <path
        fill="#FFC107"
        d="M33.9 19.5L14.8 38.6c-0.4 0.4-0.6 0.9-0.7 1.4l-2.3 10.8 10.8-2.3c0.5-0.1 1-0.4 1.4-0.7l19.1-19.1L33.9 19.5z"
      />
      {/* Light yellow highlight */}
      <path
        fill="#FFECB3"
        d="M11.8 50.8l-7.4 1.6 1.6-7.4L11.8 50.8z"
      />
      {/* Pencil tip (graphite) */}
      <path fill="#3E2723" d="M4.4 45l1.6 1.6L2 62l-1-1L4.4 45z" />
    </svg>
  );
};

export default PencilIcon;


