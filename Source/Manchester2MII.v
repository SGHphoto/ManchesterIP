`timescale 100ps/10ps
//`define Efinity_Debug

///////////////////////////////////////////////////////////
/**********************************************************
	����������
	
	��Ҫ�����ź�Ҫ��
	��ϸ��Ʒ����ļ���ţ�
	�����ļ�����
	
	���ƣ����ʲ�
	�������ڣ� 2019-9-16
	�汾��V1��0
	�޸ļ�¼��
	
2019-10-2 V1.0
===
��ʽ�����ĵ�һ���汾
===
���ܣ�
1���ṩϵͳʱ������MII�ӿڣ����Ժܷ���ĺ��ڲ��߼����ӣ�
2����MIIת�ɴ������ݣ�����LVDS����Manchester���룻
3������Manchester����������������Ρ��˲������硢������㷨�����ָ������ݣ���ת��MII�ӿڣ�
4����ȡManchester�����ʱ�ӣ�ʱ�Ӷ���С��20ns;
5����������ʱ�Ӻͱ���ʱ�ӵ�����������0.25ppm��
6�����ܵ��ݴ��㷨�����������㷨���ɴ����200ppm��Ƶ��ƫ�����ޣ������ź������йأ�

ģ����Դռ�����
=============================== 
EFX_ADD         : 	183
EFX_LUT4        : 	341
EFX_FF          : 	388
EFX_RAM_5K      : 	3
EFX_GBUFCE      : 	4
=============================== 
676LEs  3BRAMs 

ģ�����ܣ�
=======================================================
Clock Name      Period (ns)   Frequency (MHz)   Edge
SysClk              6.270         159.496     (R-R)
TxMcstClk           4.275         233.920     (R-R)
RxMcstClk           7.546         132.512     (R-R)
=======================================================

���ϸ��汾��
1��ȥ���˶����DPLL��ʵ��ʹ���л������õ�ģ�飻
2�������ʱ�ӻָ�ʱ�ӵ����ܣ�
3��ȥ����Debuger��ƽʱʹ�õĺ��ٵ��ź�


2019-10-2 V1.1
===
1��������MII���ع��ܣ�
2����VIO��������CtrlMiiLoop���źţ�
3�������˶�û�����ݵ��жϣ�������ݲ�������D0��������״̬Right��Ч����

2020-01-14 V1.2
===
1��ȥ���˵��Դ��룻
2���Ż��˴��룬�����˽�200LEs��
3����Tx��Rx�ֿ���

=============================== 
EFX_ADD         : 	67
EFX_LUT4        : 	260
EFX_FF          : 	296
EFX_RAM_5K      : 	3
EFX_GBUFCE      : 	3
=============================== 

**********************************************************/

module Mcst2MII
(   
	//System Signal
	SysClk		  ,	//(I)System Clock
	TxMcstClk   , //(I)Manchester Tx clock
	RxMcstClk   , //(I)Manchester Rx clock
	Reset_N     ,	//System Reset
	//MII Signal
	MiiRxCEn    , //(O)MII Rx Clock Enable
	MiiRxData   , //(O)MII Rx Data Input
	MiiRxDV     , //(O)MII Rx Data Valid
	MiiRxErr    , //(O)MII Rx Error
	MiiTxCEn    , //(O)MII Tx Clock Enable
	MiiTxData   , //(I)MII Tx Data Output
	MiiTxEn     , //(I)MII Tx Enable
	MiiTxBusy   , //(O)MII Tx Busy
	//Manchester Data In/Output
	TxMcstData  , //(O)Manchester Data Output
	RxMcstData  , //(I)Manchester Data In
	RxMcstLink    //(O)Manchester Linked
);

 	//Define  Parameter
	/////////////////////////////////////////////////////////
	parameter		TCo_C   		  = 1;     
	
	/////////////////////////////////////////////////////////
	//System Signal
	input 	      SysClk    ;	//ϵͳʱ��
	input         TxMcstClk ; //(I)Manchester Tx clock
	input         RxMcstClk ; //(I)Manchester Rx clock
	input					Reset_N   ;	//ϵͳ��λ
	
	/////////////////////////////////////////////////////////
	//MII Signal
	output        MiiRxCEn  ; //(O)MII Rx Clock Enable
	output  [3:0] MiiRxData ; //(O)MII Rx Data Input
	output        MiiRxDV   ; //(O)MII Rx Data Valid
	output        MiiRxErr  ; //(O)MII Rx Error
	output        MiiTxCEn  ; //(O)MII Tx Clock Enable
	input   [3:0] MiiTxData ; //(I)MII Tx Data Output
	input         MiiTxEn   ; //(I)MII Tx Enable
	output        MiiTxBusy ; //(O)MII Tx Busy
	
	/////////////////////////////////////////////////////////
	//Manchester Data In/Output
	output  [ 7:0]  TxMcstData  ; //(O)Manchester Data Output
	input   [ 7:0]  RxMcstData  ; //(I)Manchester Data In
	output          RxMcstLink  ; //(O)Manchester Linked
		
//1111111111111111111111111111111111111111111111111111111
//	
//	Input��
//	output��
//***************************************************/ 

	/////////////////////////////////////////////////////////
	reg   [2:0]   TxByteGen   = 3'h0;
	
	always @( posedge TxMcstClk)  TxByteGen <= # TCo_C TxByteGen + 3'h1;
	
	/////////////////////////////////////////////////////////
	reg   [1:0] TxByteClkReg  = 2'h0;
	reg					MiiTxCEn      = 1'h0;
	
	always @( posedge SysClk)  TxByteClkReg <= # TCo_C {TxByteClkReg[0],TxByteGen[2]};
	always @( posedge SysClk)  MiiTxCEn     <= # TCo_C  (^TxByteClkReg);
	
	/////////////////////////////////////////////////////////
	wire  [7:0] TxMcstData  ; //(O)Manchester Data Output
	wire        MiiTxBusy   ; //(O)MII Tx Busy
	
	McstTx          U1_McstTx
  (   
  	//System Signal
  	.SysClk			 (SysClk  ),	//System Clock
  	.TxMcstClk   (TxMcstClk ),  //(I)Manchester Tx clock
  	.Reset_N     (Reset_N   ),  //System Reset
  	//MII Signal
  	.MiiTxCEn    (MiiTxCEn  ),  //(I)MII Tx Clock Enable
  	.MiiTxData   (MiiTxData ),  //(I)MII Tx Data Output
  	.MiiTxEn     (MiiTxEn   ),  //(I)MII Tx Enable
	  .MiiTxBusy   (MiiTxBusy ),  //(O)MII Tx Busy
  	//Manchester Data In/Output
  	.TxMcstData  (TxMcstData)   //(O)Manchester Data Output
  );
  
//1111111111111111111111111111111111111111111111111111111



//22222222222222222222222222222222222222222222222222222
//	
//	Input��
//	output��
//***************************************************/ 

	/////////////////////////////////////////////////////////
	wire        MiiRxCEn    ; //(O)MII Rx Clock Enable
	wire  [3:0] MiiRxData   ; //(O)MII Rx Data Input
	wire        MiiRxDV     ; //(O)MII Rx Data Valid
	//Manchester Signal
	wire  [ 2:0] RxDmlitPos ; //(O)Delimite Position	
	wire  [ 7:0] RxMcstCode ; //(O)Mancheste Code Output
	wire         RxNrzDRst  ; //(O)Rx Not-Return-to-Zero Data Restore
	wire  [ 1:0] RxNrzFRst  ; //(O)Rx Not-Return-to-Zero Flag
	wire  [2:0]  RxClkAdj   ; //(O)Rx Clock Adjust Signal
	                            //[1]: AdjustEn; [0]:AjustDir, 1 faster;0 Slower	 	
	wire         RxMcstLink ; //(O)Manchester Linked
	
	McstRx  	      U2_McstRx
  (   
  	//System Signal
  	.SysClk      (SysClk    ),  //System Clock
  	.Reset_N     (Reset_N   ),  //System Reset
  	.RxMcstClk   (RxMcstClk ),  //(I)Manchester Rx clock
  	//MII Signal
  	.MiiRxCEn    (MiiRxCEn  ),  //(O)MII Rx Clock Enable
  	.MiiRxData   (MiiRxData ),  //(O)MII Rx Data Input
  	.MiiRxDV     (MiiRxDV   ),  //(O)MII Rx Data Valid
	  .MiiRxErr    (MiiRxErr  ),  //(O)MII Rx Error
  	//Manchester Signal         
  	.RxMcstData  (RxMcstData),  //(I)Manchester Data In
	  .RxMcstLink  (RxMcstLink),  //(O)Manchester Linked
	  .RxRstClk    (RxRstClk  )   //(O)Rx Restore Clock
  );
  
//22222222222222222222222222222222222222222222222222222


endmodule 







