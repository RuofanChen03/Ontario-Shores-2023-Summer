/*Bowel Function Tracking
DocumentKey			Name					DocSectKey			QuestionMnemonic		QuestionText												Type			QuestionActive
3500041			Bowel Function Tracking		BBOWELFT01			WGI.CONT00				Continent													Yes/No				Y
3500041			Bowel Function Tracking		BBOWELFT01			BBM3DY00				In the last 3 days, did the patient have a bowel movement?	Group				Y
3500041			Bowel Function Tracking		BBOWELFT01			WGI.STAM00				Amount of stool												Group				Y			
3500041			Bowel Function Tracking		BBOWELFT01			BSTOOL00				Nature of stool												Group				Y
3500041			Bowel Function Tracking		BBOWELFT01			WGI.NTRE00				Nature of stool												Group				N
3500041			Bowel Function Tracking		BBOWELFT01			BBOWELEQ00				Equipment													Group				Y
3500041			Bowel Function Tracking		BBOWELFT01			BOTHER00				Other														Comment				Y
3500041			Bowel Function Tracking		BBOWELFT01			WGI.EQUI00				Equipment													Group				N
3500041			Bowel Function Tracking		BBOWELFT01			WGI.FLUD00				Fluid intake in ml											Quantity			Y
3500041			Bowel Function Tracking		BBOWELFT01			WGI.FIBR00				Fibre intake (number of items consumed)						Number				Y
3500041			Bowel Function Tracking		BBOWELFT01			WGI.TRTM00				Bowel treatments											Group				N
3500041			Bowel Function Tracking		BBOWELFT01			WGI.RFFR00				Referrals/Consults											Group				N	
3500041			Bowel Function Tracking		BBOWELFT01			BBWLTXS00				Bowel treatments											Group				Y	
3500041			Bowel Function Tracking		BBOWELFT01			BBWLTXSCM00				If Other, please specify									Comment				Y
3500041			Bowel Function Tracking		BBOWELFT01			BREFCNSLT01				Referrals/Consults											Group				Y
*/

DROP TABLE IF EXISTS #temp_ptlist

SELECT

	--Patient Fields From PatientVisit
	PV.FacilityKey,
	PV.PatientID,
	PV.VisitID,
	PV.AccountNumber,
	PV.RegistrationType,
	PV.RegistrationStatus,
	PV.Location_CurrentLocationName,
	
	--Patient Fields From PatientInfo
	PT.PatientInitials,
	CONCAT(PV.AccountNumber,' (', PT.PatientInitials, ')') AS AccountNumberInitials


INTO #temp_ptlist


FROM DW_Dev.Patient.PatientVisit AS PV

	INNER JOIN DW_Dev.Patient.PatientInfo AS PT
		ON PV.PatientID		=	PT.PatientID

WHERE 

		PV.FacilityKey					IN ('WHA', 'OSCMHS')
	AND PV.RegistrationType				=	'IN'	
	AND PV.Location_CurrentLocationName	IN ('GDU', 'GPU', 'GTU');



DROP TABLE IF EXISTS #temp_MisQryIDs

SELECT 
	--Retrieving all required Query_MisQryID
	QuestionMnemonic AS Query_MisQryID

INTO #temp_MisQryIDs


FROM DW_Dev.MeditechDocumentation.DIM_Questions


WHERE 

	DocSectKey	=	'BBOWELFT01';



DROP TABLE IF EXISTS #RegAcctQuery_Result_OS

SELECT 

	--RAQR Fields
	RAQR.VisitID,
	RAQR.Query_MisQryID,
	RAQR.ValueInfo,
	RAQR.DateTime,
	RAQR.UrnID,
	RAQR.Source


INTO #RegAcctQuery_Result_OS


FROM livefocdb.dbo.RegAcctQuery_Result AS RAQR

	INNER JOIN #temp_ptlist AS PT
		ON RAQR.VisitID			=	PT.VisitID

	INNER JOIN #temp_MisQryIDs AS MDQ
		ON RAQR.Query_MisQryID	=	MDQ.Query_MisQryID

WHERE 

		RAQR.SourceID			=	'CEL';



SELECT DISTINCT

	--Patient Fields
	PT.FacilityKey,
	PT.VisitID,
	PT.AccountNumber,
	PT.AccountNumberInitials,
	PT.RegistrationStatus,
	PT.RegistrationType,
	PT.Location_CurrentLocationName,

	--RAQR Fields
	RAQR.UrnID,
	RAQR.DateTime		AS	[BowelFunctionTracking:Date],
	RAQR_CON.ValueInfo	AS	Continent,
	RAQR_BMT.ValueInfo	AS	BowelMovementLast3Days,
	RAQR_AMT.ValueInfo	AS	AmountofStool,
	RAQR_NS.ValueInfo	AS	NatureofStool,
	RAQR_NSI.ValueInfo	AS	NatureofStool_Inactive,
	RAQR_EQ.ValueInfo	AS	Equipment,
	RAQR_OTH.ValueInfo	AS	Other,
	RAQR_EQI.ValueInfo	AS	Equipment_Inactive,
	RAQR_FLI.ValueInfo	AS	FluidIntake,
	RAQR_FII.ValueInfo	AS	FibreIntake,
	RAQR_BTI.ValueInfo	AS	BowelTreatments_Inactive,
	RAQR_RCI.ValueInfo	AS	ReferralsConsults_Inactive,
	RAQR_BT.ValueInfo	AS	BowelTreatments,
	RAQR_BTO.ValueInfo	AS	BowelTreatments_OtherSpecify,
	RAQR_RC.ValueInfo	AS	Referrals_Consults


FROM #RegAcctQuery_Result_OS AS RAQR

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_CON
		ON	RAQR.UrnID					=	RAQR_CON.UrnID  
		AND RAQR_CON.Query_MisQryID		=	'WGI.CONT00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_BMT
		ON	RAQR.UrnID					=	RAQR_BMT.UrnID  
		AND RAQR_BMT.Query_MisQryID		=	'BBM3DY00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_AMT
		ON	RAQR.UrnID					=	RAQR_AMT.UrnID 
		AND RAQR_AMT.Query_MisQryID		=	'WGI.STAM00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_NS
		ON	RAQR.UrnID					=	RAQR_NS.UrnID 
		AND RAQR_NS.Query_MisQryID		=	'BSTOOL00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_NSI
		ON	RAQR.UrnID					=	RAQR_NSI.UrnID
		AND RAQR_NSI.Query_MisQryID		=	'WGI.NTRE00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_EQ
		ON	RAQR.UrnID					=	RAQR_EQ.UrnID 
		AND RAQR_EQ.Query_MisQryID		=	'BBOWELEQ00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_OTH
		ON	RAQR.UrnID					=	RAQR_OTH.UrnID 
		AND RAQR_OTH.Query_MisQryID		=	'BOTHER00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_EQI
		ON	RAQR.UrnID					=	RAQR_EQI.UrnID 
		AND RAQR_EQI.Query_MisQryID		=	'WGI.EQUI00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_FLI
		ON	RAQR.UrnID					=	RAQR_FLI.UrnID 
		AND RAQR_FLI.Query_MisQryID		=	'WGI.FLUD00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_FII
		ON	RAQR.UrnID					=	RAQR_FII.UrnID 
		AND RAQR_FII.Query_MisQryID		=	'WGI.FIBR00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_BTI
		ON	RAQR.UrnID					=	RAQR_BTI.UrnID 
		AND RAQR_BTI.Query_MisQryID		=	'WGI.TRTM00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_RCI
		ON	RAQR.UrnID					=	RAQR_RCI.UrnID 
		AND RAQR_RCI.Query_MisQryID		=	'WGI.RFFR00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_BT
		ON	RAQR.UrnID					=	RAQR_BT.UrnID 
		AND RAQR_BT.Query_MisQryID		=	'BBWLTXS00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_BTO
		ON	RAQR.UrnID					=	RAQR_BTO.UrnID 
		AND RAQR_BTO.Query_MisQryID		=	'BBWLTXSCM00'

	LEFT JOIN #RegAcctQuery_Result_OS AS RAQR_RC
		ON	RAQR.UrnID					=	RAQR_RC.UrnID 
		AND RAQR_RC.Query_MisQryID		=	'BREFCNSLT01'

	INNER JOIN #temp_ptlist AS PT
		ON	RAQR.VisitID				=	PT.VisitID 

ORDER BY RAQR.DateTime;