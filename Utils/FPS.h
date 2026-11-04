//
//  FPS.h
//  LienQuanVNMod
//
//  Created by Le Tien Dat on 6/6/26.
//

#ifndef FPS_h
#define FPS_h

#include <chrono>

struct RealtimeFpsState {
    std::chrono::steady_clock::time_point lastFrameTime;
    std::chrono::steady_clock::time_point lastSampleTime;
    double accumulatedSeconds = 0.0;
    int accumulatedFrames = 0;
    float deltaTime = 1.0f / 120.0f;
    float fps = 120.0f;
};

static RealtimeFpsState gRealtimeFpsState;

static void UpdateRealtimeFps() {
    auto now = std::chrono::steady_clock::now();

    if (gRealtimeFpsState.lastFrameTime.time_since_epoch().count() == 0) {
        gRealtimeFpsState.lastFrameTime = now;
        gRealtimeFpsState.lastSampleTime = now;
        gRealtimeFpsState.deltaTime = 1.0f / 120.0f;
        gRealtimeFpsState.fps = 120.0f;
        return;
    }

    double deltaSeconds =
        std::chrono::duration<double>(now - gRealtimeFpsState.lastFrameTime)
            .count();
    gRealtimeFpsState.lastFrameTime = now;

    if (deltaSeconds <= 0.0) {
        deltaSeconds = 1.0 / 120.0;
    }

    if (deltaSeconds > 0.25) {
        deltaSeconds = 0.25;
    }

    gRealtimeFpsState.deltaTime = (float)deltaSeconds;
    gRealtimeFpsState.accumulatedSeconds += deltaSeconds;
    gRealtimeFpsState.accumulatedFrames += 1;

    if (gRealtimeFpsState.accumulatedSeconds >= 0.35) {
        float sampledFps = (float)(gRealtimeFpsState.accumulatedFrames /
                                   gRealtimeFpsState.accumulatedSeconds);
        gRealtimeFpsState.fps =
            (gRealtimeFpsState.fps * 0.65f) + (sampledFps * 0.35f);
        gRealtimeFpsState.accumulatedSeconds = 0.0;
        gRealtimeFpsState.accumulatedFrames = 0;
        gRealtimeFpsState.lastSampleTime = now;
    }
}

static float GetRealtimeFps() { return gRealtimeFpsState.fps; }

static void DrawTabBarFpsBadge() {
    ImGuiContext &g = *GImGui;
    ImGuiTabBar *tabBar = g.CurrentTabBar;
    if (!tabBar || !g.CurrentWindow)
        return;

    char fpsLabel[32];
    snprintf(fpsLabel, sizeof(fpsLabel), "%.1f FPS", GetRealtimeFps());

    ImFont *font = ImGui::GetFont();
    float fontSize = ImGui::GetFontSize();
    ImVec2 textSize = font->CalcTextSizeA(fontSize, FLT_MAX, 0.0f, fpsLabel);

    ImRect barRect = tabBar->BarRect;

    float textX = barRect.Max.x - textSize.x;
    float textY = barRect.Min.y + ((barRect.GetHeight() - textSize.y) * 0.5f);

    ImDrawList *draw = ImGui::GetWindowDrawList();
    draw->AddText(font, fontSize, ImVec2(textX, textY),
                  IM_COL32(97, 207, 90, 255), fpsLabel);
}

#endif /* FPS_h */
