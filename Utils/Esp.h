#pragma once

#import "../IMGUI/imgui.h"
#import "../Utils/HookUtils.h"
#import "../Utils/RuntimeMacros.h"
#import "Color.hpp"
#import "Vector2.h"

#define ARGB(a, r, g, b) 0 | a << 24 | r << 16 | g << 8 | b
#define SCREEN_WIDTH (float)[UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT (float)[UIScreen mainScreen].bounds.size.height

const float ESP_BOX_WIDTH = 100.0f;
const float ESP_BOX_HEIGHT = 200.0f;

float Rainbow() {
    static float x = 0, y = 0;
    static float r = 0, g = 0, b = 0;
    if (y >= 0.0f && y < 255.0f) {
        r = 255.0f;
        g = 0.0f;
        b = x;
    } else if (y >= 255.0f && y < 510.0f) {
        r = 255.0f - x;
        g = 0.0f;
        b = 255.0f;
    } else if (y >= 510.0f && y < 765.0f) {
        r = 0.0f;
        g = x;
        b = 255.0f;
    } else if (y >= 765.0f && y < 1020.0f) {
        r = 0.0f;
        g = 255.0f;
        b = 255.0f - x;
    } else if (y >= 1020.0f && y < 1275.0f) {
        r = x;
        g = 255.0f;
        b = 0.0f;
    } else if (y >= 1275.0f && y < 1530.0f) {
        r = 255.0f;
        g = 255.0f - x;
        b = 0.0f;
    }
    x += 0.25f;
    if (x >= 255.0f)
        x = 0.0f;
    y += 0.25f;
    if (y > 1530.0f)
        y = 0.0f;
    return ARGB(255, (int)r, (int)g, (int)b);
}

class ESP {
  public:
    void drawText(const char *text, float X, float Y, float size, long color) {
        ImGui::GetBackgroundDrawList()->AddText(NULL, size, ImVec2(X, Y), color,
                                                text);
    }

    void drawLine(float startX, float startY, float stopX, float stopY,
                  float thicc, long color) {
        ImGui::GetBackgroundDrawList()->AddLine(
            ImVec2(startX, startY), ImVec2(stopX, stopY), color, thicc);
    }

    void drawBorder(float X, float Y, float width, float height, float thicc,
                    long color) {
        ImGui::GetBackgroundDrawList()->AddRect(
            ImVec2(X, Y), ImVec2(X + width, Y + height), color, thicc);
    }

    void drawBox(float X, float Y, float width, float height, float thicc,
                 long color) {
        ImGui::GetBackgroundDrawList()->AddRectFilled(
            ImVec2(X, Y), ImVec2(X + width, Y + height), color, thicc);
    }

    void drawCornerBox(int x, int y, int w, int h, float thickness,
                       long color) {
        int iw = w / 4;
        int ih = h / 4;

        ImGui::GetBackgroundDrawList()->AddLine(ImVec2(x, y), ImVec2(x + iw, y),
                                                color, thickness);
        ImGui::GetBackgroundDrawList()->AddLine(ImVec2(x, y), ImVec2(x, y + ih),
                                                color, thickness);
        ImGui::GetBackgroundDrawList()->AddLine(
            ImVec2(x + w - 1, y), ImVec2(x + w - 1, y + ih), color, thickness);
        ImGui::GetBackgroundDrawList()->AddLine(
            ImVec2(x, y + h), ImVec2(x + iw, y + h), color, thickness);
        ImGui::GetBackgroundDrawList()->AddLine(
            ImVec2(x + w - iw, y + h), ImVec2(x + w, y + h), color, thickness);
        ImGui::GetBackgroundDrawList()->AddLine(
            ImVec2(x, y + h - ih), ImVec2(x, y + h), color, thickness);
        ImGui::GetBackgroundDrawList()->AddLine(ImVec2(x + w - 1, y + h - ih),
                                                ImVec2(x + w - 1, y + h), color,
                                                thickness);
    }
};

void drawFixedESPBox(ImDrawList *draw, ImVec2 centerPos) {
    ImVec2 min = ImVec2(centerPos.x - ESP_BOX_WIDTH / 2,
                        centerPos.y - ESP_BOX_HEIGHT / 2);
    ImVec2 max = ImVec2(centerPos.x + ESP_BOX_WIDTH / 2,
                        centerPos.y + ESP_BOX_HEIGHT / 2);
    draw->AddRect(min, max, IM_COL32(255, 255, 255, 255), 0.0f, 0, 1.0f);
}

bool isOutsideScreen(ImVec2 pos, ImVec2 screen) {
    if (pos.y < 0) {
        return true;
    }
    if (pos.x > screen.x) {
        return true;
    }
    if (pos.y > screen.y) {
        return true;
    }
    return pos.x < 0;
}

void DrawCd(ImDrawList *draw, ImVec2 position, float size, ImU32 color,
            int cd) {
    ImVec2 points[4] = {ImVec2(position.x - size, position.y),
                        ImVec2(position.x, position.y - size),
                        ImVec2(position.x + size, position.y),
                        ImVec2(position.x, position.y + size)};
    if (cd == 0) {
        draw->AddConvexPolyFilled(points, 4, color);

    } else {

        // draw->AddConvexPolyFilled(points, 4, IM_COL32(255, 255, 255, 255));
        auto textSize = ImGui::CalcTextSize(std::to_string(cd).c_str(), 0,
                                            ((float)SCREEN_HEIGHT / 30.0f));
        draw->AddText(
            ImGui::GetFont(), ((float)SCREEN_HEIGHT / 30.0f),
            {position.x - (textSize.x / 2), position.y - (textSize.y / 2)},
            ImColor(0, 255, 0, 255), std::to_string(cd).c_str());
    }
}

ImVec2 pushToScreenBorder(ImVec2 Pos, ImVec2 screen, int offset) {
    int x = (int)Pos.x;
    int y = (int)Pos.y;

    if (Pos.y < 0) {
        y = -offset;
    }

    if (Pos.x > screen.x) {
        x = (int)screen.x + offset;
    }

    if (Pos.y > screen.y) {
        y = (int)screen.y + offset;
    }

    if (Pos.x < 0) {
        x = -offset;
    }
    return ImVec2(x, y);
}

void DrawCircleHealth(ImVec2 position, int health, int max_health,
                      float radius) {
    float a_max = ((3.14159265359f * 2.0f));
    ImU32 healthColor = IM_COL32(45, 180, 45, 255);
    if (health <= (max_health * 0.6)) {
        healthColor = IM_COL32(180, 180, 45, 255);
    }
    if (health < (max_health * 0.3)) {
        healthColor = IM_COL32(180, 45, 45, 255);
    }
    ImGui::GetForegroundDrawList()->PathArcTo(
        position, radius,
        (-(a_max / 4.0f)) + (a_max / max_health) * (max_health - health),
        a_max - (a_max / 4.0f));
    ImGui::GetForegroundDrawList()->PathStroke(healthColor, ImDrawFlags_None,
                                               4);
}

void DrawCircleHealth2(ImVec2 position, int health, int max_health,
                       float radius) {
    float a_max = ((3.14159265359f * 2.0f));
    ImU32 healthColor = IM_COL32(45, 180, 45, 255);
    if (health <= (max_health * 0.6)) {
        healthColor = IM_COL32(180, 180, 45, 255);
    }
    if (health < (max_health * 0.3)) {
        healthColor = IM_COL32(180, 45, 45, 255);
    }
    ImGui::GetForegroundDrawList()->PathArcTo(
        position, radius,
        (-(a_max / 4.0f)) + (a_max / max_health) * (max_health - health),
        a_max - (a_max / 4.0f));
    ImGui::GetForegroundDrawList()->PathStroke(healthColor, ImDrawFlags_None,
                                               1.7);
}

Color colorByDistance(int distance, float alpha) {
    Color _colorByDistance;
    if (distance < 450)
        _colorByDistance = Color(255, 0, 0, alpha);
    if (distance < 200)
        _colorByDistance = Color(255, 0, 0, alpha);
    if (distance < 121)
        _colorByDistance = Color(0, 10, 51, alpha);
    if (distance < 51)
        _colorByDistance = Color(0, 67, 0, alpha);
    return _colorByDistance;
}
Vector2 pushToScreenBorder(Vector2 Pos, Vector2 screen, int offset) {
    int X = (int)Pos.x;
    int Y = (int)Pos.y;
    if (Pos.y < 50) {
        // top
        Y = 42 - offset;
    }
    if (Pos.x > screen.x) {
        // right
        X = (int)screen.x + offset;
    }
    if (Pos.y > screen.y) {
        // bottom
        Y = (int)screen.y + offset;
    }
    if (Pos.x < 60) {
        // left
        X = 20 - offset;
    }
    return Vector2(X, Y);
}
bool isOutsideSafeZone(Vector2 pos, Vector2 screen) {
    if (pos.y < 60) {
        return true;
    }
    if (pos.x > screen.x) {
        return true;
    }
    if (pos.y > screen.y) {
        return true;
    }
    return pos.x < 50;
}

class Camera {
  public:
    static Camera *get_main() {
        Camera *(*get_main_)() =
            (Camera * (*)()) getRealOffset(ENCRYPTOFFSET("0x7357438"));
        return get_main_();
    }

    Vector3 WorldToScreenPoint(Vector3 position) {
        Vector3 (*WorldToScreenPoint_)(Camera *camera, Vector3 position) =
            (Vector3(*)(Camera *, Vector3))getRealOffset(
                ENCRYPTOFFSET("0x7356AF0"));
        return WorldToScreenPoint_(this, position);
    }

    Vector3 WorldToScreen(Vector3 position) {
        Vector3 (*WorldToViewportPoint_)(Camera *camera, Vector3 position,
                                         int eye) =
            (Vector3(*)(Camera *, Vector3, int))getRealOffset(
                ENCRYPTOFFSET("0x73567F0"));

        return WorldToViewportPoint_(this, position, 2);
    }
};

ImU32 ToColor(int r, int g, int b, int a) { return IM_COL32(r, g, b, a); }

void Draw3dBox(ImDrawList *draw, Vector3 Transform, Camera *camera) {
    Vector3 position2 = Transform + Vector3(0.6, 1.6, 0.6);
    Vector3 position3 = Transform + Vector3(0.6, 0, 0.6);
    Vector3 position4 = Transform + Vector3(-0.5, 0, 0.6);
    Vector3 position5 = Transform + Vector3(-0.5, 1.6, 0.6);
    Vector3 position6 =
        (Transform + Vector3(0.6, 1.6, 0)) + Vector3(0, 0, -0.6);
    Vector3 position7 = (Transform + Vector3(0.6, 0, 0)) + Vector3(0, 0, -0.6);
    Vector3 position8 = (Transform + Vector3(-0.5, 0, 0)) + Vector3(0, 0, -0.6);
    Vector3 position9 =
        (Transform + Vector3(-0.5, 1.6, 0)) + Vector3(0, 0, -0.6);

    Vector3 vector = camera->WorldToScreenPoint(position2);
    Vector3 vector2 = camera->WorldToScreenPoint(position3);
    Vector3 vector3 = camera->WorldToScreenPoint(position4);
    Vector3 vector4 = camera->WorldToScreenPoint(position5);
    Vector3 vector5 = camera->WorldToScreenPoint(position6);
    Vector3 vector6 = camera->WorldToScreenPoint(position7);
    Vector3 vector7 = camera->WorldToScreenPoint(position8);
    Vector3 vector8 = camera->WorldToScreenPoint(position9);

    if (vector.z > 0 && vector2.z > 0 && vector3.z > 0 && vector4.z > 0 &&
        vector5.z > 0 && vector6.z > 0 && vector7.z > 0 && vector8.z > 0) {
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector.x)),
                       (SCREEN_HEIGHT - vector.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector2.x),
                       SCREEN_HEIGHT - vector2.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector3.x)),
                       (SCREEN_HEIGHT - vector3.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector2.x),
                       SCREEN_HEIGHT - vector2.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector.x)),
                       (SCREEN_HEIGHT - vector.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector4.x),
                       SCREEN_HEIGHT - vector4.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector4.x)),
                       (SCREEN_HEIGHT - vector4.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector3.x),
                       SCREEN_HEIGHT - vector3.y},
                      ToColor(255, 0, 0, 255), 2.0f);

        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector5.x)),
                       (SCREEN_HEIGHT - vector5.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector6.x),
                       SCREEN_HEIGHT - vector6.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector7.x)),
                       (SCREEN_HEIGHT - vector7.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector6.x),
                       SCREEN_HEIGHT - vector6.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector5.x)),
                       (SCREEN_HEIGHT - vector5.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector8.x),
                       SCREEN_HEIGHT - vector8.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector8.x)),
                       (SCREEN_HEIGHT - vector8.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector7.x),
                       SCREEN_HEIGHT - vector7.y},
                      ToColor(255, 0, 0, 255), 2.0f);

        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector.x)),
                       (SCREEN_HEIGHT - vector.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector5.x),
                       SCREEN_HEIGHT - vector5.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector2.x)),
                       (SCREEN_HEIGHT - vector2.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector6.x),
                       SCREEN_HEIGHT - vector6.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector3.x)),
                       (SCREEN_HEIGHT - vector3.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector7.x),
                       SCREEN_HEIGHT - vector7.y},
                      ToColor(255, 0, 0, 255), 2.0f);
        draw->AddLine({(float)(SCREEN_WIDTH - (SCREEN_WIDTH - vector4.x)),
                       (SCREEN_HEIGHT - vector4.y)},
                      {SCREEN_WIDTH - (SCREEN_WIDTH - vector8.x),
                       SCREEN_HEIGHT - vector8.y},
                      ToColor(255, 0, 0, 255), 2.0f);
    }
}
