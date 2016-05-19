/* BuildingTagC.nc
* - main control for the building tag mote
* Basic capabilities:
* - report information when queried
* - be programmable with new information as required
* 
*/

//	NEW: NOW CONTAINS SINK ELECTION AND RPL


configuration BuildingTagAppC { }

implementation 
{
	//			--------BOILERPLATE AND RPL--------
	
	components MainC, BuildingTagC as App;
	App.Boot -> MainC;
	
	//	blip?
	components IPStackC;
	components IPDispatchC;
	components IPProtocolsP;
	App.SplitControl -> IPStackC;

	//	rpl?
	components RPLRankC;
	components RPLRoutingEngineC;
	components RPLDAORoutingEngineC;
	components RPLRoutingC;
	App.RPLDAO -> RPLDAORoutingEngineC;
	App.RPLRoute -> RPLRoutingEngineC;
	App.RootControl -> RPLRoutingEngineC;
	App.RoutingControl -> RPLRoutingEngineC;
	
	components IPForwardingEngineP;
	App.RoutingTable -> IPForwardingEngineP.ForwardingTable;

	//			--------TIMERS--------	
	components new TimerMilliC() as ElectionTimer; 
	App.ElectionTimer -> ElectionTimer;

	components new TimerMilliC() as BatteryVoltageTimer; 
	App.BatteryVoltageTimer -> BatteryVoltageTimer;

	components new TimerMilliC() as DataTimer; 
	App.DataTimer -> DataTimer;
	
	components new TimerMilliC() as BroadTimer; 
	App.BroadTimer -> BroadTimer;

	components new TimerMilliC() as SendTimer; 
	App.SendTimer -> SendTimer;

// 	components new TimerMilliC() as TestTimer; 
// 	App.TestTimer -> TestTimer;
	
	components new TimerMilliC() as ResetBeaconTimer; 
	App.ResetBeaconTimer -> ResetBeaconTimer;
	
	components new TimerMilliC() as RootSelectionTimer; 
	App.RootSelectionTimer -> RootSelectionTimer;
	
	
	//			--------SOCKETS AND NETWORK--------
	components new UdpSocketC() as DataUDP;
	App.BtagDataUDP -> DataUDP;
	
	components new UdpSocketC() as ElectionUDP;
	App.ElectionUDP -> ElectionUDP;
	
	components new UdpSocketC() as ReportUDP;
	App.BeaconRecvUDP -> ReportUDP;
	
	components new UdpSocketC() as ProgrammerUDP;
	App.ProgrammerUDP -> ProgrammerUDP;
	
	components new UdpSocketC() as RootSelectUDP;
	App.RootSelectUDP -> RootSelectUDP;
	

	//			--------MISC--------
	components LedsC;
	App.Leds -> LedsC;
	
	components new DemoSensorC();
	App.BatteryVoltageRead -> DemoSensorC;
	
	components RandomC;
	App.Random -> RandomC;

	
	//#ifdef PRINTFUART_ENABLED
		components SerialPrintfC;
	//	components SerialStartC;
	//#endif
	
	//components PlatformSerialC;
	//App.UartStream -> PlatformSerialC.UartStream;

}
