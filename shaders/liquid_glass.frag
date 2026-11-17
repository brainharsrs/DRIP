// Liquid Glass do DRIP: vidro grosso em forma de retângulo arredondado/pílula.
//
// Usado como ImageFilter.shader dentro de um BackdropFilter. O motor entrega
// o fundo já desenhado em `uTexture` e o tamanho dessa textura em `uTexSize`.
//
// O que o shader faz, de fora para dentro:
//   1. SDF da caixa arredondada: sabe a distância de cada pixel até a borda.
//   2. Refração na borda (rim bending): na faixa do bisel, a leitura do fundo
//      é deslocada ao longo da normal com peso pow(1 - t, 2.4), e o miolo
//      ganha uma leve ampliação, como uma lente.
//   3. Aberração cromática: R, G e B são lidos em pontos um pouco diferentes,
//      só onde a borda curva.
//   4. Luz especular vinda de cima à esquerda (-0.55, -0.85): um filete
//      brilhante na quina e um reflexo mais fraco na borda oposta.
//   5. Tinta do material por cima (adapta ao tema claro/escuro).

#include <flutter/runtime_effect.glsl>

uniform vec2 uTexSize;   // definido pelo motor: tamanho da textura de fundo
uniform vec4 uRect;      // x, y, largura, altura da caixa (px físicos)
uniform float uRadius;   // raio dos cantos (px físicos)
uniform float uBevel;    // largura da faixa curva da borda (px físicos)
uniform float uBend;     // intensidade da refração (px físicos)
uniform float uDark;     // 1 = tema escuro, 0 = claro
uniform vec4 uTint;      // cor da tinta (rgb) e quanto dela aplicar (a)

uniform sampler2D uTexture;

out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 halfSize, float r) {
  vec2 q = abs(p) - halfSize + r;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

vec4 sampleBackdrop(vec2 px) {
  vec2 uv = clamp(px / uTexSize, vec2(0.0), vec2(1.0));
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

void main() {
  vec2 p = FlutterFragCoord().xy;

  // Alguns backends entregam só o recorte da caixa como textura, outros a
  // tela inteira. Se a textura tem o tamanho da caixa, a origem é (0, 0).
  vec4 rect = uRect;
  if (abs(uTexSize.x - rect.z) < 4.0 && abs(uTexSize.y - rect.w) < 4.0) {
    rect.xy = vec2(0.0);
  }

  vec2 halfSize = rect.zw * 0.5;
  vec2 center = rect.xy + halfSize;
  float r = min(uRadius, min(halfSize.x, halfSize.y));
  vec2 lp = p - center;

  // Fora da caixa, `aa` (abaixo) vale 0 e o fundo passa sem mudança.
  float d = sdRoundBox(lp, halfSize, r);

  // Normal da borda (gradiente do SDF), apontando para fora.
  float e = 1.0;
  vec2 n = vec2(
    sdRoundBox(lp + vec2(e, 0.0), halfSize, r) - sdRoundBox(lp - vec2(e, 0.0), halfSize, r),
    sdRoundBox(lp + vec2(0.0, e), halfSize, r) - sdRoundBox(lp - vec2(0.0, e), halfSize, r)
  );
  n = n / max(length(n), 1e-4);

  float bevel = max(uBevel, 1.0);
  float t = clamp(-d / bevel, 0.0, 1.0);   // 0 na borda, 1 no miolo
  float rim = pow(1.0 - t, 2.4);

  // Refração: puxa a leitura para dentro ao longo da normal na borda e
  // amplia levemente o miolo (lê mais perto do centro).
  float minSide = min(halfSize.x, halfSize.y);
  vec2 bend = -n * rim * uBend;
  vec2 magnify = -lp * 0.035 * t * clamp(minSide / 40.0, 0.0, 1.0);
  vec2 offset = bend + magnify;

  // Aberração cromática só na curvatura.
  vec2 fringe = n * rim * uBend * 0.22;
  vec4 base = sampleBackdrop(p + offset);
  float red = sampleBackdrop(p + offset + fringe).r;
  float blue = sampleBackdrop(p + offset - fringe).b;
  vec3 col = vec3(red, base.g, blue);

  // Tinta do material.
  col = mix(col, uTint.rgb, uTint.a);

  // Luz especular direcional (cima-esquerda) + reflexo na borda oposta.
  vec2 light = normalize(vec2(-0.55, -0.85));
  float edgeBand = pow(1.0 - t, 7.0);
  float key = pow(max(dot(n, light), 0.0), 3.0) * edgeBand;
  float back = pow(max(dot(n, -light), 0.0), 4.0) * edgeBand;
  float keyStrength = mix(0.55, 0.38, uDark);
  float backStrength = mix(0.22, 0.16, uDark);
  col += vec3(key * keyStrength + back * backStrength);

  // No tema claro, um leve escurecimento interno dá corpo ao vidro.
  col -= vec3(rim * 0.035 * (1.0 - uDark));

  // Borda suavizada (o recorte do widget faz o resto).
  float aa = clamp(0.5 - d, 0.0, 1.0);
  vec4 outside = sampleBackdrop(p);
  vec4 glass = vec4(clamp(col, 0.0, 1.0) * base.a, base.a);
  fragColor = mix(outside, glass, aa);
}
