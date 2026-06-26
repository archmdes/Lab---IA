# Validação Lógica: Fluxo de Inferência da CNN em Hardware

Este documento é um roteiro completo, detalhado e técnico focado em comprovar, de forma irrefutável via **SignalTap II Logic Analyzer**, que todo o cálculo algébrico e tomada de decisão da Rede Neural Convolucional ocorre fisicamente nos blocos lógicos sintetizados na FPGA, e que os dados utilizados para essa matemática vêm estritamente de memórias internas já consolidadas (desacopladas da interface de transmissão do PC).

---

## 1. Objetivo Geral
Provar que a inferência da rede (extração de características e classificação matemática) é um processo endógeno (nativo do hardware). Para isso, devemos demonstrar graficamente na linha do tempo que:
1. Os dados da imagem de entrada terminaram de ser recebidos via UART e já estão 100% alojados, aguardando na memória local.
2. A Máquina de Estados da CNN (FSM) desperta de forma autônoma e orquestra a leitura ativa dessa memória para gerar os endereços X e Y.
3. Os sinais varrem os pipelines matemáticos seqüencialmente (`valid_out` de cada camada).
4. O bloco Argmax calcula localmente o maior valor lógico e retém a predição na saída.

---

## 2. Sinais Críticos e Como Encontrá-los

No Quartus, utilizando a janela **Node Finder** com o filtro definido para `Design Entry (all names)` ou `SignalTap II: pre-synthesis`, busque e adicione a seguinte hierarquia de nós à análise. 

**Atenção aos Formatos:** Certifique-se de configurar a coluna *Radix* no SignalTap exatamente como listado abaixo para cada sinal/barramento, de forma a garantir uma interpretação fluida na hora da apresentação e defesa.

### 2.1. Fim da Carga Externa (Prova de Memória)
* **`UART_RXD`** (Pino direto de Top-Level)
  * **Formato (Radix):** `Binary` (Nível lógico do pino externo).
* **`uart_wr_en_comb`** (Escrita na RAM)
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|uart_wr_en_comb`
  * **Formato (Radix):** `Binary`
* **`uart_start_pulse`** (Gatilho da Inferência)
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|uart_start_pulse`
  * **Formato (Radix):** `Binary` (Deverá ser visto como um pulso fino de 1 único clock).

### 2.2. Despertar do Cérebro FSM e Leitura Nativa
* **`state`** (Estado atual da máquina, 3 bits)
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|state`
  * **Formato (Radix):** `Unsigned Decimal` (Facilita ver a mudança nítida do estado `0` para o estado `3`).
* **`fb_rd_en`** e **`fb_rd_addr`** (Leitura varrendo o buffer)
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|fb_rd_en` e `...|fb_rd_addr`
  * **Formato (Radix):** `Binary` e `Unsigned Decimal`, respectivamente. O endereço decimal subindo gradualmente até 1023 exibe a leitura 2D da imagem.

### 2.3. Propagação Lógica pelo Pipeline Matemático
* **`valid_out` do Pooling** (Marca o fim da Convolução + Maxpool)
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|max_pooling_design:pool_inst|valid_out`
  * **Formato (Radix):** `Binary` (Veremos uma vasta cortina contínua de uns e zeros).
* **`valid_out` da Camada Densa**
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|dense_900x19_scores:dense_inst|valid_out`
  * **Formato (Radix):** `Binary` (Aqui observaremos pequenos disparos ritmados ocorrendo muito mais tarde no tempo).

### 2.4. Resultado Final (Classificação)
* **`valid_out` do Argmax** (Sinal de prontidão do score)
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|argmax_19:argmax_inst|valid_out`
  * **Formato (Radix):** `Binary` (Deverá aparecer como um pulso único e isolado concluindo tudo).
* **`class_id`** (Índice inteiro predito)
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|argmax_19:argmax_inst|class_id`
  * **Formato (Radix):** `Unsigned Decimal` (Permite ler explicitamente a classe predita: 0, 1, 15, 19).

### 2.5. Saída Consolidada de Top-Level
* **`access_done`** e **`display_class_id`**
  * **Caminho:** `fpga_top_unified|access_done` e `fpga_top_unified|display_class_id`
  * **Formato (Radix):** `Binary` e `Unsigned Decimal`.

---

## 3. Justificativas Individualizadas de Prova

Cada sinal acima constitui um pilar inquebrável para a prova de que a lógica é pura de hardware, sem CPUs, sem microcontroladores embutidos.

### 3.1. Sinais de Recepção (`UART_RXD` e `uart_wr_en_comb` vs `fb_rd_en`)
* **Origem:** O grupo "wr" vem da desserialização assíncrona da placa, enquanto o grupo "rd" provém da FSM interna operando a rigorosos 50MHz controlados pelo cristal.
* **Interpretação e Uso na Prova (O Desacoplamento):** É essencial exibir estes dois grupos ao mesmo tempo na tela. A banca precisa ver que a FSM (o hardware local) **só começa a gerar ordens de leitura (`fb_rd_en = 1`) após** a interface externa (UART) calar a boca e o `uart_wr_en_comb` cessar seus pulsos completamente, permanecendo liso em `0`. A separação temporal irrefutável mostra que o computador transferiu o pacote fechado de pixels e encerrou sua atuação. A partir daquele pulso vazio em diante, todo o processamento recaiu sobre a engenharia de fluxo da FPGA.

### 3.2. Sinais de Controle FSM (`state` e `fb_rd_addr`)
* **Origem:** Registradores internos sequenciais gerados via Verilog.
* **Interpretação e Uso na Prova:** A demonstração empírica da orquestração nativa. O registrador decimal `state` pulando de `0` (IDLE) para `3` (READ), aliado ao registrador de endereço `fb_rd_addr` escalando em loops finitos, prova mecanicamente a inteligência local varrendo o array da memória e despachando os pixels para as convoluções de forma assustadoramente rápida.

### 3.3. Sinais de Propagação Matemática (`valid_out` das Camadas)
* **Origem:** Sinais independentes produzidos no fim de cada etapa do pipeline algébrico marcando que o tensor local atual foi computado com sucesso e os Mac's terminaram.
* **Interpretação e Uso na Prova:** Eis a prova visual do Pipeline Superescalar de Hardware. Você verá um efeito cascata. O dado entra; milhares de ciclos *depois* o `pool_valid` (Binary) começa a pulsar furiosamente (provando latência arquitetural, ou seja, tempo físico gasto com matemática vetorial nas Multiplicadoras/DSPs). Uma enormidade de ciclos *depois* dessa onda convolucional, a Camada Densa entra em jogo e aciona o seu `dense_valid`. Esse empilhamento visual com claros abismos de tempo prova fisicamente o trânsito dos tensores passando por estruturas físicas diferentes no Silício.

### 3.4. O Veredito de Decisão (`argmax` e `display_class_id`)
* **Origem:** Módulo comparador aritmético e registradores instanciados diretos no topo do hierárquico ligados aos displays de Sete Segmentos.
* **Interpretação e Uso na Prova:** Ao concluir a onda matemática, a última subcamada entrega as probabilidades. O Argmax devolve um único valor não-fracionário em Decimal: a classe predita. Provar que o pulso de `access_done` no Top-level espelha instantaneamente esse valor no `display_class_id` de forma nativa e paralela, atesta que não houve rotinas lentas de `printf`, mas sim hardware síncrono acendendo o display final.

---

## 4. Configuração Passo a Passo no SignalTap

A configuração para rastrear a CNN exige precisão porque o evento da matemática, para os padrões do SignalTap, é imenso (dezenas de milhares de clocks), mas seu estopim dura um único pulso.

### Passo 4.1: Escolha do Clock de Amostragem
* **Configuração Exigida:** No campo `Clock`, adicione incontestavelmente o nó `CLOCK_50` (Pino Y2).
* **Por quê?** Todo o sistema da CNN foi parametrizado, cronometrado e roteado em uma topologia fixa de 50 MHz. Sem ele, os registradores pipeline aparecerão descompassados.

### Passo 4.2: Profundidade da Amostra (Sample Depth)
* **Configuração Exigida:** Utilize um Sample Depth bastante profundo. Se sua placa aguentar, suba para **`32 K` ou `64 K` amostras**. 
* **O Motivo Tático:** A latência arquitetônica – o abismo de tempo entre a FSM injetar o pixel e a saída final brotar no Argmax – leva muitos, muitos ciclos devido às divisões de imagens e acúmulos multiplicativos seriais. Se você usar um depth curto, a gravação do analisador vai acabar antes que a "onda de dados" chegue sequer na Camada Densa.

### Passo 4.3: Posição do Trigger (Trigger Position)
* **Configuração Ideal:** `Pre-trigger position`. Reserve estritamente entre **10% e 20% do buffer para pré-gatilho**.
* **O Motivo Tático:** Retomando o desafio central (Provar que o PC parou de enviar e a FPGA assumiu). Aqueles parcos 10% de "passado visual" na tela capturarão os esporros finais da gravação do PC (`uart_wr_en_comb` subindo e descendo frenético, e então congelando no 0). É a prova do bastão sendo passado.

### Passo 4.4: Condição de Gatilho (Trigger Condition)
Onde armar a "armadilha":
- Identifique na tabela o nó `fpga_top_unified|cnn_top:cnn_inst|uart_start_pulse`.
- Clique com o botão direito na coluna de gatilho dele e defina a condição para **Rising Edge** (Borda de subida) ou sinal fixo `1` (Basic AND).
- **A Mágica:** Compile e suba. O Quartus ficará aguardando o silêncio. Ao apertar o comando no terminal do PC finalizando a transferência de uma foto, o cérebro local da placa dirá *"pacote cheio!"* e levantará a bandeira do `uart_start_pulse` por míseros 20 nanossegundos. O SignalTap vai fisgar a isca, e a tela piscará desenhando a "morte" da UART externa à esquerda e a ressurreição brutal dos fluxos vetoriais e cálculos de endereço brotando do nada à direita. O argumento definitivo para sua defesa.
