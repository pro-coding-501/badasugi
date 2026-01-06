import React, { useEffect, useRef, useState, useCallback } from "react";
import { listen } from "@tauri-apps/api/event";
import "./AudioVisualizer.css";

interface AudioVisualizerProps {
  isRecording: boolean;
  barCount?: number;
}

const AudioVisualizer: React.FC<AudioVisualizerProps> = ({
  isRecording,
  barCount = 6,
}) => {
  const [levels, setLevels] = useState<number[]>(Array(barCount).fill(0));
  const smoothedLevelsRef = useRef<number[]>(Array(barCount).fill(0));
  const animationFrameRef = useRef<number>();

  // Listen for mic-level events from Tauri backend
  useEffect(() => {
    let unlistenFn: (() => void) | null = null;

    const setupListener = async () => {
      console.log("🎵 mic-level 이벤트 리스너 설정 중...");
      unlistenFn = await listen<number[]>("mic-level", (event) => {
        if (!isRecording) {
          console.log("⏸️ 녹음 중이 아니므로 mic-level 무시");
          return;
        }

        const newLevels = event.payload;
        console.log("📊 mic-level 수신:", newLevels.length, "개 샘플");
        
        // Sample levels evenly across the frequency data
        const sampledLevels = Array(barCount)
          .fill(0)
          .map((_, i) => {
            const index = Math.floor((i / barCount) * newLevels.length);
            return newLevels[index] || 0;
          });

        // Apply smoothing for fluid animation
        smoothedLevelsRef.current = smoothedLevelsRef.current.map((prev, i) => {
          const target = sampledLevels[i] || 0;
          // Faster rise, slower fall for natural feel
          const alpha = target > prev ? 0.4 : 0.15;
          return prev + (target - prev) * alpha;
        });

        setLevels([...smoothedLevelsRef.current]);
      });
      console.log("✅ mic-level 리스너 설정 완료");
    };

    if (isRecording) {
      setupListener();
    }

    return () => {
      if (unlistenFn) unlistenFn();
    };
  }, [isRecording, barCount]);

  // Fallback: Web Audio API for direct microphone visualization
  const [audioContext, setAudioContext] = useState<AudioContext | null>(null);
  const [analyser, setAnalyser] = useState<AnalyserNode | null>(null);
  const mediaStreamRef = useRef<MediaStream | null>(null);

  const startWebAudioVisualization = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaStreamRef.current = stream;

      const ctx = new AudioContext();
      const analyserNode = ctx.createAnalyser();
      analyserNode.fftSize = 64;
      analyserNode.smoothingTimeConstant = 0.8;

      const source = ctx.createMediaStreamSource(stream);
      source.connect(analyserNode);

      setAudioContext(ctx);
      setAnalyser(analyserNode);
    } catch (error) {
      console.error("Failed to access microphone:", error);
    }
  }, []);

  const stopWebAudioVisualization = useCallback(() => {
    if (mediaStreamRef.current) {
      mediaStreamRef.current.getTracks().forEach((track) => track.stop());
      mediaStreamRef.current = null;
    }
    if (audioContext) {
      audioContext.close();
      setAudioContext(null);
    }
    setAnalyser(null);
    // Reset levels to zero
    setLevels(Array(barCount).fill(0));
    smoothedLevelsRef.current = Array(barCount).fill(0);
  }, [audioContext, barCount]);

  // Animation loop for Web Audio API fallback
  useEffect(() => {
    if (!analyser || !isRecording) {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
      return;
    }

    const dataArray = new Uint8Array(analyser.frequencyBinCount);

    const updateLevels = () => {
      analyser.getByteFrequencyData(dataArray);

      // Sample data evenly for each bar
      const sampledLevels = Array(barCount)
        .fill(0)
        .map((_, i) => {
          const start = Math.floor((i / barCount) * dataArray.length);
          const end = Math.floor(((i + 1) / barCount) * dataArray.length);
          let sum = 0;
          for (let j = start; j < end; j++) {
            sum += dataArray[j];
          }
          return (sum / (end - start) / 255) || 0;
        });

      // Apply smoothing
      smoothedLevelsRef.current = smoothedLevelsRef.current.map((prev, i) => {
        const target = sampledLevels[i] || 0;
        const alpha = target > prev ? 0.5 : 0.2;
        return prev + (target - prev) * alpha;
      });

      setLevels([...smoothedLevelsRef.current]);
      animationFrameRef.current = requestAnimationFrame(updateLevels);
    };

    updateLevels();

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current);
      }
    };
  }, [analyser, isRecording, barCount]);

  // Start/stop based on recording state
  useEffect(() => {
    if (isRecording) {
      startWebAudioVisualization();
    } else {
      stopWebAudioVisualization();
    }

    return () => {
      stopWebAudioVisualization();
    };
  }, [isRecording]);

  return (
    <div className={`audio-visualizer ${isRecording ? "recording" : ""}`}>
      <div className="bars-wrapper">
        {levels.map((level, index) => (
          <div
            key={index}
            className="audio-bar"
            style={{
              height: `${Math.max(4, level * 40)}px`,
              opacity: isRecording ? Math.max(0.4, level + 0.3) : 0.3,
              animationDelay: `${index * 0.05}s`,
            }}
          />
        ))}
      </div>
    </div>
  );
};

export default AudioVisualizer;

