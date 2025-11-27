library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Tipos_Elevadores.all;

entity Top_Level is
    port (
        clk             : in std_logic;
        reset           : in std_logic;

        -- Entradas Externas (Pulsos)
        btn_corredor_subir  : in std_logic_vector(ULTIMO_ANDAR downto 0);
        btn_corredor_descer : in std_logic_vector(ULTIMO_ANDAR downto 0);

        -- Entradas Internas (Pulsos)
        btn_cabines_in      : in matriz_botoes(2 downto 0);
        
        -- Saídas
        leds_andar_0        : out std_logic_vector(4 downto 0);
        leds_andar_1        : out std_logic_vector(4 downto 0);
        leds_andar_2        : out std_logic_vector(4 downto 0);
        leds_porta_aberta   : out std_logic_vector(2 downto 0)
    );
end entity;

architecture Structural of Top_Level is

    -- SINAIS DE CONEXÃO
    signal s_destinos_alvo  : matriz_andar(2 downto 0);
    signal s_direcoes_req   : vetor_direcao(2 downto 0);
    signal s_andares_atuais : matriz_andar(2 downto 0);
    signal s_direcoes_reais : vetor_direcao(2 downto 0); 
    
    -- SINAIS FÍSICOS
    type t_bus_motor is array (0 to 2) of std_logic;
    signal s_motor_enable, s_move_up, s_move_down : t_bus_motor;
    signal s_door_closed, s_door_open : t_bus_motor;
    signal s_start_open, s_start_close : t_bus_motor;

    -- MEMÓRIAS DOS BOTÕES (LATCHES)
    signal s_botoes_internos_mem : matriz_botoes(2 downto 0); 
    
    -- [CORREÇÃO] NOVAS MEMÓRIAS PARA O CORREDOR
    signal s_memoria_subir  : std_logic_vector(ULTIMO_ANDAR downto 0);
    signal s_memoria_descer : std_logic_vector(ULTIMO_ANDAR downto 0);

begin

    -- ========================================================================
    -- 1. GESTÃO DE MEMÓRIA DE TODOS OS BOTÕES
    -- ========================================================================
    process(clk, reset)
        variable andar_atual_int : integer;
    begin
        if reset = '1' then
            s_botoes_internos_mem <= (others => (others => '0'));
            s_memoria_subir       <= (others => '0');
            s_memoria_descer      <= (others => '0');
        elsif rising_edge(clk) then
            
            -- 1.1. LATCH (Captura o pulso e mantém '1')
            -----------------------------------------------------
            for i in 0 to 2 loop
                s_botoes_internos_mem(i) <= s_botoes_internos_mem(i) OR btn_cabines_in(i);
            end loop;

            -- Memoriza chamados do corredor
            s_memoria_subir  <= s_memoria_subir  OR btn_corredor_subir;
            s_memoria_descer <= s_memoria_descer OR btn_corredor_descer;


            -- 1.2. CLEAR (Limpa a memória quando a porta abre)
            -----------------------------------------------------
            for i in 0 to 2 loop
                if s_door_open(i) = '1' then
                    andar_atual_int := safe_to_integer(s_andares_atuais(i));
                    
                    -- Limpa pedido interno
                    s_botoes_internos_mem(i)(andar_atual_int) <= '0';
                    
                    -- Limpa pedidos externos daquele andar
                    s_memoria_subir(andar_atual_int)  <= '0';
                    s_memoria_descer(andar_atual_int) <= '0';
                end if;
            end loop;
            
        end if;
    end process;

    -- ========================================================================
    -- 2. SUPERVISOR GLOBAL (LIGADO NAS MEMÓRIAS)
    -- ========================================================================
    U_Supervisor: entity work.Supervisor_Global
        port map (
            botoes_in            => s_botoes_internos_mem, 
            botoes_subir_in      => s_memoria_subir,       -- [CORREÇÃO] Usa a memória
            botoes_descer_in     => s_memoria_descer,      -- [CORREÇÃO] Usa a memória
            
            andaresElevadores_in => s_andares_atuais,
            direcaoElevadores_in => s_direcoes_reais, 
            proximoAndar_out     => s_destinos_alvo,
            direcao_req_out      => s_direcoes_req
        );

    -- ========================================================================
    -- 3. GERAÇÃO DOS 3 ELEVADORES
    -- ========================================================================
    gen_elevadores: for i in 0 to 2 generate

        s_direcoes_reais(i) <= SUBINDO  when s_move_up(i) = '1' else
                               DESCENDO when s_move_down(i) = '1' else
                               PARADO;

        U_Controlador: entity work.Controlador
            port map (
                CLK              => clk,
                RESET            => reset,
                andar_atual_in   => s_andares_atuais(i),
                andar_destino_in => s_destinos_alvo(i), 
                direcao_req_in   => s_direcoes_req(i),  
                door_closed_in   => s_door_closed(i),
                door_open_in     => s_door_open(i),
                botao_abrir_in   => '0',
                botao_fechar_in  => '0',
                motor_enable_out => s_motor_enable(i),
                move_up_out      => s_move_up(i),
                move_down_out    => s_move_down(i),
                start_open_out   => s_start_open(i),
                start_close_out  => s_start_close(i)
            );

        U_Planta_Motor: entity work.somador_andar 
            generic map (G_TIME_PER_FLOOR => 50) 
            port map (clk => clk, reset => reset, motor_enable_in => s_motor_enable(i), move_up_in => s_move_up(i), move_down_in => s_move_down(i), andar_atual_out => s_andares_atuais(i), moving_out => open);

        U_Porta: entity work.porta 
            generic map (G_MAX_COUNT => 100)
            port map (clk => clk, reset => reset, start_close => s_start_close(i), start_open => s_start_open(i), door_closed => s_door_closed(i), door_open => s_door_open(i));

    end generate;

    -- Conexões de Saída
    leds_andar_0 <= s_andares_atuais(0);
    leds_andar_1 <= s_andares_atuais(1);
    leds_andar_2 <= s_andares_atuais(2);
    leds_porta_aberta(0) <= s_door_open(0);
    leds_porta_aberta(1) <= s_door_open(1);
    leds_porta_aberta(2) <= s_door_open(2);

end architecture;