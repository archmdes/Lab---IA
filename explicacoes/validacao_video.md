# Validação Lógica: Fluxo de Exibição de Imagem e Chaveamento de Framebuffers

Este documento é um roteiro completo, detalhado e técnico focado em comprovar visualmente e empiricamente, utilizando o analisador lógico **SignalTap II Logic Analyzer** do Quartus Prime, que todo o fluxo de vídeo trafega e é decidido puramente em hardware.

---

## 1. Objetivo Geral
Provar de ponta a ponta (end-to-end) que os bytes brutos chegam pela porta serial (UART), são internalizados e gravados nos blocos de memória da FPGA (Framebuffers) e que o Controlador VGA efetivamente puxa (lê) esses dados destas memórias internas para plotar na tela. 

Adicionalmente, provaremos que o hardware altera fisicamente sua fonte de leitura (fazendo o chaveamento entre o Framebuffer de Vídeo 128x128 e o Framebuffer de Rosto 32x32) baseando-se unicamente no comando interno interpretado (`frame_mode`), atestando a independência e a inteligência local da FPGA sem depender do computador para trocar o fluxo na tela.

---

## 2. Sinais Críticos e Como Encontrá-los

Para evitar problemas de renderização no Quartus ou no visualizador, optou-se pela lista de sinais abaixo. Utilize a ferramenta **Node Finder** no SignalTap (botão direito -> Add Nodes), selecione o filtro `Design Entry (all names)` ou `SignalTap II: pre-synthesis` e busque pelos nomes exatos descritos na hierarquia.

**Atenção aos Formatos:** Como o SignalTap exibe formas de onda (waveforms), agrupe os barramentos multibits e clique com o botão direito na coluna *Radix* para ajustar o formato de exibição recomendado abaixo para cada caso, facilitando a interpretação.

### 2.1. Sinais de Recepção Externa
* **`UART_RXD`**
  * **Caminho no Node Finder:** `UART_RXD` (Pino direto de Top-Level).
  * **Formato de exibição (Radix):** `Binary` (Veremos apenas as oscilações de 1s e 0s assíncronos da linha serial).

### 2.2. Sinais de Internalização e Escrita
* **`uart_wr_en_comb`** 
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|uart_wr_en_comb`
  * **Formato (Radix):** `Binary` (Pulso lógico indicando gravação).
* **`uart_wr_addr`** 
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|uart_wr_addr`
  * **Formato (Radix):** `Unsigned Decimal` (Permitirá ver graficamente o endereço subindo de 0 até 16383 de forma escalonada, como uma escada perfeita).
* **`data_out` (Byte decodificado da UART)**
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|uart_rx:uart_rx_inst|data_out`
  * **Formato (Radix):** `Hexadecimal` (Ideal para enxergar pacotes como o cabeçalho mágico `0xFF` ou os pixels puros `0x8A`, `0x4F`).

### 2.3. Sinais de Decisão e Chaveamento
* **`frame_mode`**
  * **Caminho:** `fpga_top_unified|cnn_top:cnn_inst|frame_mode`
  * **Formato (Radix):** `Binary` (Nível lógico puro: 0 = Vídeo, 1 = Rosto).
* **`display_mode`**
  * **Caminho:** `fpga_top_unified|display_mode`
  * **Formato (Radix):** `Binary`.

### 2.4. Sinais de Leitura Nativa do VGA
* **`video_vga_rd_data` (Dados lidos da memória de Vídeo 128x128)**
  * **Caminho:** `fpga_top_unified|video_vga_rd_data`
  * **Formato (Radix):** `Hexadecimal` (Permite ver a variação veloz do tom de cinza do vídeo).
* **`vga_rd_data` (Dados lidos da memória de Rosto 32x32)**
  * **Caminho:** `fpga_top_unified|vga_rd_data`
  * **Formato (Radix):** `Hexadecimal`.

### 2.5. Sinais de Projeção na Tela
* **`VGA_R`, `VGA_G`, `VGA_B`**
  * **Caminho:** Pinos diretos de Top-Level (`VGA_R`, etc).
  * **Formato (Radix):** `Hexadecimal` (Por serem vetores de 8 bits, agrupe-os e exiba em Hex. Para a banca, ficará claro que eles copiarão os valores idênticos dos sinais de Leitura listados acima).

---

## 3. Justificativas Individualizadas de Prova

Nesta seção, destrinchamos detalhadamente por que cada um dos sinais listados foi escolhido, de onde ele vem e qual o seu peso probatório. A presença conjunta desses sinais na mesma janela temporal destrói qualquer argumentação de que o processamento é mascarado ou feito externamente.

### 3.1. Pino `UART_RXD`
* **Origem:** Pino físico injetado direto no Top-Level advindo do cabo USB-Serial conectado ao PC.
* **Interpretação e Uso na Prova:** Serve como âncora da "realidade externa". Mostrar esse sinal oscilando descompassadamente (modo assíncrono) é a prova bruta de que o dado original está chegando. Se a imagem não estivesse de fato transitando, este pino estaria calado em nível lógico alto (`1`).

### 3.2. Os Sinais de Internalização (`uart_wr_en_comb`, `uart_wr_addr`, `data_out`)
* **Origem:** Gerados pelo módulo de recepção `uart_rx` (desserializador) e processados pela lógica combinacional da UART no arquivo `cnn_top.v`.
* **Interpretação e Uso na Prova:** O computador envia pulsos físicos (1s e 0s soltos no pino). Ao observar no analisador lógico o `data_out` agregando e assumindo valores de pixels válidos em Hex, acompanhados por pulsos ritmados (nível alto no `uart_wr_en_comb`) e o incremento decimal sequencial do `uart_wr_addr`, provamos matematicamente que o hardware FPGA compreendeu o formato da transmissão e **salvou ativamente a imagem** dentro de um chip M9K na placa, sem depender da CPU de um PC.

### 3.3. Sinais de Chaveamento (`frame_mode` e `display_mode`)
* **Origem:** O `frame_mode` nasce no módulo `cnn_top.v` a partir da detecção do byte mágico `0xFF` da UART. O `display_mode` é o seu espelho no Top-Level, re-sincronizado para a frequência da interface de vídeo.
* **Interpretação e Uso na Prova:** Eles são a representação visual da "vontade" do chip. Quando a UART detecta a intenção do usuário, este sinal (Binary) sobe ou desce. Observá-lo mudando de estado no exato momento da chegada de um novo frame prova a capacidade de decisão interna do hardware.

### 3.4. Os Sinais Duplos de Leitura (`video_vga_rd_data` e `vga_rd_data`)
* **Origem:** Vêm das portas de saída de leitura dos dois framebuffers físicos distintos alocados em RAM block.
* **Interpretação e Uso na Prova:** Esta é a Prova Cabal. Na tela do SignalTap, ambos os sinais mostrarão valores Hex caóticos oscilando a 25MHz. No entanto, por serem memórias segregadas, eles quase sempre diferem um do outro. Ao exibir os dois, provamos inquestionavelmente a existência física das memórias duplas (não é um mero software alterando imagens na mesma tela).

### 3.5. A Saída Real (`VGA_R`, `VGA_G`, `VGA_B`)
* **Origem:** Lógica de multiplexador no topo da hierarquia, ligada aos pinos de saída D-SUB (VGA).
* **Interpretação e Uso na Prova:** Quando a FSM muda o `display_mode` para `1`, você notará os hexadecimais dos pinos `VGA_R/G/B` deixarem de copiar o sinal `video_vga_rd_data` e passarem a ser cópias literais do sinal `vga_rd_data`. Isso conclui o teorema: A imagem na tela advém do banco de memória interno selecionado fisicamente pela placa.

---

## 4. Configuração Passo a Passo no SignalTap

Para capturar com sucesso esse comportamento que une o evento lento (transmissão UART) ao evento extremamente veloz do controlador VGA, a configuração do clock e do gatilho é estrita.

### Passo 4.1: Escolha do Clock de Amostragem (SignalTap Clock)
O fluxo da UART e da CNN roda a 50MHz, enquanto o VGA roda nativamente a 25MHz. 
* **Configuração Exigida:** No campo `Clock` do painel do SignalTap, adicione o nó principal do sistema: `CLOCK_50` (Pino Y2).
* **Detalhe para a Banca:** Como a amostragem será feita no clock rápido de 50MHz, os eventos sincronizados do VGA (25MHz) aparecerão redundantes (cada byte na waveform de `VGA_R` ou `vga_rd_data` vai durar exatos 2 ciclos de clock na tela antes de mudar). Explique isso à banca: demonstra enorme domínio do conceito de domínios de clock (Clock Domains) e valida que o VGA está rodando na metade da velocidade da lógica principal, como desenhado.

### Passo 4.2: Profundidade da Amostra (Sample Depth)
Um frame de vídeo completo via UART a 115200 bps demora quase 1.5 segundos.
* **Configuração:** **Utilize um Sample Depth modesto (como `4 K` ou `8 K`)**. O objetivo da prova não é gravar a imagem toda, mas sim engarrafar o **microssegundo da transição**, onde o comando final chega, a recepção acaba e as leituras de memória se invertem instantaneamente.

### Passo 4.3: Posição do Trigger (Trigger Position)
- **Configuração Obrigatória:** `Pre-trigger position`. Configure o Quartus para guardar entre **10% a 20% do buffer dedicado ao pré-gatilho**. 
- **O que isso faz na prática?** Precisamos provar a alternância ao vivo. Com 20% de pre-trigger, a onda mostrará o passado recente à esquerda da tela (o sistema operando normalmente no Modo Vídeo, com os RGBs espelhando o buffer 128x128). Ao centro (momento do trigger), a quebra de estado no pino respectivo. À direita (80% restantes), o futuro provado (o sistema engatado no Modo Rosto, espelhando os dados do buffer 32x32). É a foto de "antes e depois" definitiva.

### Passo 4.4: Condição de Gatilho (Trigger Condition)
Onde aplicar a lupa e dizer pro Quartus "grave isso":
- Na tabela do SignalTap, vá até a linha do sinal interno `frame_mode`.
- Defina o Trigger dele clicando com botão direito na coluna de gatilho para **Rising Edge** (Borda de subida).
- **A Mágica:** O Quartus ficará gravando o fluxo VGA continuamente na placa, sobrescrevendo a memória em loop sem incomodar. Assim que você enviar a imagem de rosto pela interface python, o último byte mudará o estado interno, e o `frame_mode` vai subir para 1. O SignalTap vai travar o instantâneo e enviar o gráfico da transição para a sua tela. Um atestado irretocável de hardware funcional.
