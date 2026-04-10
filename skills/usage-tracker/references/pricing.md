# Precios Claude por modelo (Anthropic API — abril 2026)

Precios en USD por millón de tokens (MTok). Tasa USD→EUR: ~0.92.

## Tabla de precios

| Modelo (settings.json) | Input $/MTok | Output $/MTok | Input €/tok    | Output €/tok   |
|------------------------|-------------|---------------|----------------|----------------|
| opus                   | 15.00       | 75.00         | 0.0000138      | 0.0000690      |
| sonnet                 | 3.00        | 15.00         | 0.00000276     | 0.0000138      |
| haiku                  | 0.80        | 4.00          | 0.000000736    | 0.00000368     |

## Mapeo de IDs a categoría de precio

Los valores en el campo `model` del log pueden ser:
- `"opus"` → precio Opus
- `"sonnet"` → precio Sonnet  
- `"haiku"` → precio Haiku
- Cualquier otro valor → usar Sonnet como fallback

## Fórmula

```python
PRICES = {
    "opus":   {"in": 0.0000138,   "out": 0.0000690},
    "sonnet": {"in": 0.00000276,  "out": 0.0000138},
    "haiku":  {"in": 0.000000736, "out": 0.00000368},
}

def cost_eur(tok_in, tok_out, model="sonnet"):
    p = PRICES.get(model, PRICES["sonnet"])
    return tok_in * p["in"] + tok_out * p["out"]
```

## Nota importante

Estos son precios de API. **Claude Max es suscripción fija** — el coste en €
calculado aquí es un índice relativo para comparar el peso entre sesiones,
proyectos y modelos. No es el coste monetario real de la suscripción Max.

El modelo Opus cuesta ~25x más por token que Haiku. Si cambias de Sonnet
a Opus para una tarea pesada, el coste estimado se multiplica por ~5.
