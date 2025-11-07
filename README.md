![Main Banner](https://i.imgur.com/hryKQ1w.png)

## Overview (EN)
This repository is a fork of [QuantumMalice/vehiclehandler](https://github.com/QuantumMalice/vehiclehandler). The upstream project did not include fall-sensitive wheel damage, motorcycle support or burst-driven degradation when this fork was created; these additions live exclusively here for now.

## Visão Geral (PT-BR)
Este repositório é um fork de [QuantumMalice/vehiclehandler](https://github.com/QuantumMalice/vehiclehandler). A versão original não possuía detecção sensível a quedas, suporte a motocicletas nem degradação progressiva com pneu estourado quando este fork foi criado; essas funcionalidades existem apenas aqui por enquanto.

## __Gameplay Features (EN)__
➢ Tire loss on impact <br>
➢ Reduces torque based on current health <br>
➢ Prevents crazy handling from low fuel <br>
➢ Disables vehicle after heavy collisions <br>
➢ Disables controls while airborne/flipped <br>
➢ Repair/Wash item integration (clean, tire, engine) <br>
➢ Detects harsh landings and bursts wheels according to impact angle *(fork addition)* <br>
➢ Supports motorcycles when bursting wheels *(fork addition)* <br>
➢ Gradually damages engine/body while driving with burst tires *(fork addition)* <br>

## __Recursos de Gameplay (PT-BR)__
➢ Estouro de pneus em colisões <br>
➢ Redução de torque conforme a saúde atual <br>
➢ Impede condução instável com combustível baixo <br>
➢ Desativa o veículo após colisões severas <br>
➢ Bloqueia controles enquanto o veículo está no ar ou virado <br>
➢ Integração com itens de reparo/lavagem (limpeza, pneu, motor) <br>
➢ Detecta pousos bruscos e estoura pneus conforme o ângulo do impacto *(adição do fork)* <br>
➢ Suporta motocicletas ao estourar pneus *(adição do fork)* <br>
➢ Danifica gradualmente motor/carroceria ao dirigir com pneus estourados *(adição do fork)* <br>

## __Configuration Highlights (EN)__
All tuning lives in `data/vehicle.lua`. Besides the original multipliers and thresholds, this fork introduces:

```
fall = {
    enabled = true,
    minHeight = 6.0, -- meters of drop before a landing is treated as harsh
    minSpeed = 30.0, -- km/h (or mph) vertical speed threshold
},

burst = {
    degradation = 10,   -- health drained per tick while driving on burst tires
    thresholdSpeed = 10 -- km/h (or mph) horizontal speed required to start draining
},
```

Set `units = 'kmh'` or `'mph'` to match your preferred system; all thresholds adapt automatically.

## __Destaques de Configuração (PT-BR)__
Toda a calibragem está em `data/vehicle.lua`. Além dos multiplicadores e limites originais, este fork adiciona:

```
fall = {
    enabled = true,
    minHeight = 6.0, -- metros de queda para considerar o pouso severo
    minSpeed = 30.0, -- km/h (ou mph) de velocidade vertical mínima
},

burst = {
    degradation = 10,   -- dano aplicado por ciclo ao dirigir com pneus estourados
    thresholdSpeed = 10 -- km/h (ou mph) mínimos para começar a degradar
},
```

Defina `units = 'kmh'` ou `'mph'` conforme o sistema desejado; os limites se ajustam automaticamente.

## __Dependencies / Dependências__
* [ox_lib](https://github.com/CommunityOx/ox_lib)
* [ox_inventory](https://github.com/CommunityOx/ox_inventory) *(Optional / Opcional)*

## ***ox_inventory***
```lua
    ["cleaningkit"] = {
        label = "Cleaning Kit",
        weight = 250,
        stack = true,
        close = true,
        description = "A microfiber cloth with some soap will let your car sparkle again!",
        client = {
            image = "cleaningkit.png",
        },
        server = {
            export = 'vehiclehandler.cleaningkit'
        }
    },

    ["tirekit"] = {
        label = "Tire Kit",
        weight = 250,
        stack = true,
        close = true,
        description = "A nice toolbox with stuff to repair your tire",
        client = {
            image = "tirekit.png",
        },
        server = {
            export = 'vehiclehandler.tirekit'
        }
    },

    ["repairkit"] = {
        label = "Repairkit",
        weight = 2500,
        stack = true,
        close = true,
        description = "A nice toolbox with stuff to repair your vehicle",
        client = {
            image = "repairkit.png",
        },
        server = {
            export = 'vehiclehandler.repairkit',
        }
    },

    ["advancedrepairkit"] = {
        label = "Advanced Repairkit",
        weight = 5000,
        stack = true,
        close = true,
        description = "A nice toolbox with stuff to repair your vehicle",
        client = {
            image = "advancedrepairkit.png",
        },
        server = {
            export = 'vehiclehandler.advancedrepairkit',
        }
    },
```
