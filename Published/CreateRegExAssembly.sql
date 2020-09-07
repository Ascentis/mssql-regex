/* Source code for the library at: https://github.com/Ascentis/mssql-regex */

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExIsMatch]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExIsMatch
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatch]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatch
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchIndexed]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchIndexed
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExSplit]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExSplit
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplace]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExReplace
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExReplaceCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExReplaceCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExEscape]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExEscape
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExUnescape]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExUnescape
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatches]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatches
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroup]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchGroup
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchGroupIndexed]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchGroupIndexed
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExMatchesGroup]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExMatchesGroup
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExCachedCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExCachedCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExClearCache]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExClearCache
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExExecCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExExecCount
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[RegExResetExecCount]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION RegExResetExecCount
GO

IF EXISTS (select *
	from sys.assembly_files f
	full outer join  sys.assemblies a
		on f.assembly_id=a.assembly_id
	where a.name ='Ascentis.RegExSQL')
	DROP ASSEMBLY [Ascentis.RegExSQL]
GO

IF EXISTS(SELECT *
		  from sys.configurations	
		  where name = 'clr strict security' and value = 0)
	EXEC SP_CONFIGURE 'clr strict security', 1
GO

RECONFIGURE
GO

DECLARE @clrName nvarchar(4000) = 'Ascentis.RegExSql';
DECLARE @asmBin varbinary(max) = 0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A2400000000000000504500004C010300C7FD65970000000000000000E00022200B013000001A00000008000000000000423900000020000000400000000000100020000000020000040000000000000006000000000000000080000000020000B9150100030060850000100000100000000010000010000000000000100000000000000000000000ED3800004F000000004000006C04000000000000000000000000000000000000006000000C00000068380000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002E746578740000004819000000200000001A000000020000000000000000000000000000200000602E727372630000006C0400000040000000060000001C0000000000000000000000000000400000402E72656C6F6300000C000000006000000002000000220000000000000000000000000000400000420000000000000000000000000000000021390000000000004800000002000500BC2400002C13000009000000000000000000000000000000E83700008000000000000000000000000000000000000000000000000000000000000000000000002E731100000A80010000042AAE7E01000004027E05000004252D17267E04000004FE061A000006731200000A2580050000046F1300000A2A1330020026000000010000117F02000004281400000A260228020000060A0612016F1500000A2D08020673160000060B072A4A0302741F000001731600000A81140000012A0000001B30020022000000020000110328030000060A06026F1700000A6F1800000A0BDE0A062C06066F1900000ADC072A000001100000020007000F16000A000000001B3003001E000000030000110328030000060A0602046F1A00000A0BDE0A062C06066F1900000ADC072A000001100000020007000B12000A000000001B3004001F000000030000110328030000060A060204056F1B00000A0BDE0A062C06066F1900000ADC072A0001100000020007000C13000A000000001B3002001D000000040000110328030000060A06026F1C00000A0BDE0A062C06066F1900000ADC072A00000001100000020007000A11000A000000001E02281D00000A2A1E02281E00000A2A1B30020022000000030000110328030000060A06026F1700000A6F1F00000A0BDE0A062C06066F1900000ADC072A000001100000020007000F16000A000000001B3002003A000000050000110328030000060A06026F2000000A0B04076F2100000A2F0E07046F2200000A6F1F00000A2B0572010000700CDE0A062C06066F1900000ADC082A00000110000002000700272E000A000000001B3002002D000000030000110328030000060A06026F1700000A6F2300000A046F2400000A6F1F00000A0BDE0A062C06066F1900000ADC072A00000001100000020007001A21000A000000001B30020045000000050000110328030000060A06026F2000000A0B05076F2100000A2F1907056F2200000A6F2300000A046F2400000A6F1F00000A2B0572010000700CDE0A062C06066F1900000ADC082A00000001100000020007003239000A000000001B3003004B000000040000110328030000060A06026F2000000A280100002B7E06000004252D17267E04000004FE061B000006732600000A258006000004280200002B280300002B0BDE0A062C06066F1900000ADC072A000110000002000700383F000A000000001B3003004500000006000011731D0000060A06047D080000040328030000060B07026F2000000A280100002B06FE061E000006732600000A280200002B280300002B0CDE0A072C06076F1900000ADC082A00000001100000020014002539000A00000000AA7E010000047E07000004252D17267E04000004FE061C000006732900000A258007000004280400002B2A567E010000046F2B00000A7E010000046F2C00000A2A22FE137E020000042A42FE137E0200000416FE1380020000042A1E02282D00000A2A4202031E282E00000A02047D030000042A36027B03000004026F2F00000A2A2E731900000680040000042A1E02282D00000A2A1A733000000A2A1E036F1F00000A2A360F01283100000A6F3200000A2A1E02282D00000A2A5E036F2300000A027B080000046F2400000A6F1F00000A2A0042534A4201000100000000000C00000076342E302E33303331390000000005006C000000D4060000237E0000400700000C07000023537472696E6773000000004C0E00000400000023555300500E0000100000002347554944000000600E0000CC04000023426C6F62000000000000000200000157170208090A000000FA013300160000010000002500000005000000080000001E0000002800000001000000320000002000000006000000060000000100000004000000030000000400000000005104010000000000060045036E050600B2036E05060064023C050F008E05000006008C0285040600280385040600F402850406009903850406006503850406007E0385040600A3028504060078024F05060056024F050600D70285040600BE02EB0306001D067A040600D80054060600B00054060600DD016E050A000504B2050A00130310050600C501E6050E009704C7050E00FE06C7050600D1017A0406003B026E050600C2007A040E003104C7050600C900290106004D01DA03060008047A040E00F204C7050E002B02C7050E00A704C7051200C601FE040600A20029010E00F905C70500000000F3000000000001000100010000005901000041000100010004001000F806000061000300160003211000250100004100040018000301100048000000410008001D0031006704150211009F06220221004A0427023600EF002F0216000100330216002000400216005E0049020600F8045B02502000000000911831055E0201005C200000000094003C0462020100882000000000940012026C020200BA20000000009600E60672020300D02000000000960022047A0205001021000000009600A001800207004C21000000009600BB0687020A0088210000000096002B068F020E00C421000000009600E80196001000CC21000000009600FC0196001100D4210000000096000F0496021200142200000000960067019C0214006C22000000009600C6049C021700B8220000000096008101A3021A001C230000000096009D058F021E008423000000009600DE04AB022000E823000000009600AA06B30223001324000000009600B501B302230029240000000096009006B302230032240000000096007C06B302230043240000000086182B05060023004B240000000083182B05B70223005C2400000000E6013302060025006A2400000000911831055E02250076240000000086182B05060025007E240000000083000A00C202250085240000000083002A00CC0226008D240000000083006800D20227009B240000000086182B0506002800A3240000000083008200CC02280000000100B70400000100B70400000100EE0602000200380500000100E00600000200B70400000100E00600000200B704000003003E0600000100E00600000200B704000003003E0600000400D50600000100E00600000200B70400000100E00600000100E00600000100E00600000200B70400000100E00600000200B70400000300F20600000100E00600000200B70400000300F80400000100E00600000200B70400000300F80400000400F20600000100E00600000200B70400000100E00600000200B70400000300F80400000100B704000002004B04000001000E01000001008304000001004B040000010083040300650009002B05010011002B05060019002B050A0029002B05100031002B05100039002B05100041002B05100049002B05100051002B05100059002B05100061002B05150069002B05100071002B05100079002B051000A9002B050600D1002B0506000C002B05060014002B0532000C0044013800F1004A0652001C00BF045F00A1002B051000C10031046C00010111067200C90033020600C100AD017C00C100AD018200C10038069000C100F5019600C100090296000901D0039B00C100AA05A700B9007206AD00B9007104B100E1000606B70011017104BD001901DB06C40024002B05320019012406DE0019010407FE002C002B053200190181042A010C007206AD000C000A05060081002B050600C1002B054B011C00370453011C002B0506003400D00365011C007206AD002E000B00E1022E001300EA022E001B0009032E00230012032E002B0020032E00330077032E003B007D032E00430012032E004B009D032E00530077032E005B0077032E006300B5032E006B00DF032E007300EC0383008300C404A0007B003A04A3008300C404C0007B003A04E0007B003A0400017B005F0420017B003A0440017B003A0460017B003A0480017B003A04A0017B003A04C0017B003A04E0017B005F0400027B005F0420027B003A0440027B003A0460027B003A0480027B003A0447006600760089009F0010011A0026005800D60019015901048000000100000000000100010000007301FC0000000400000000000000000000006A011C01000000000400000000000000000000006A011001000000000400000000000000000000006A017A04000000000400000000000000000000006A011F02000000000300020004000200050002004B00D1004F00F80051000C0155003D0100000000003C3E395F5F345F30003C4765745265676578537461636B3E625F5F345F30003C3E395F5F31375F30003C5265674578436F6D70696C65644D6174636865733E625F5F31375F30003C3E635F5F446973706C6179436C61737331385F30003C3E395F5F31395F30003C5265674578436163686564436F756E743E625F5F31395F30003C5265674578436F6D70696C65644D61746368657347726F75703E625F5F300049456E756D657261626C65603100436F6E63757272656E74537461636B60310046756E636032004B657956616C756550616972603200436F6E63757272656E7444696374696F6E6172796032003C3E39003C4D6F64756C653E00417363656E7469732E526567457853514C005F0053797374656D2E44617461006D73636F726C6962003C3E630053797374656D2E436F6C6C656374696F6E732E47656E65726963004765744F7241646400496E7465726C6F636B6564005265674578436F6D70696C6564005265674578436F6D70696C65644D61746368496E6465786564005265674578436F6D70696C65644D6174636847726F7570496E6465786564005265674578436F6D70696C65645265706C616365005265674578436C65617243616368650049456E756D657261626C650049446973706F7361626C65004973566F6C6174696C65005265674578436F6D70696C6564457363617065005265674578436F6D70696C6564556E657363617065005265676578416371756972650053797374656D2E436F7265004361707475726500446973706F736500436F6D70696C657247656E65726174656441747472696275746500477569644174747269627574650044656275676761626C6541747472696275746500436F6D56697369626C6541747472696275746500417373656D626C795469746C6541747472696275746500417373656D626C7954726164656D61726B417474726962757465005461726765744672616D65776F726B41747472696275746500417373656D626C7946696C6556657273696F6E41747472696275746500417373656D626C79436F6E66696775726174696F6E4174747269627574650053716C46756E6374696F6E41747472696275746500417373656D626C794465736372697074696F6E41747472696275746500436F6D70696C6174696F6E52656C61786174696F6E7341747472696275746500417373656D626C7950726F6475637441747472696275746500417373656D626C79436F7079726967687441747472696275746500417373656D626C79436F6D70616E794174747269627574650052756E74696D65436F6D7061746962696C697479417474726962757465006765745F56616C75650053797374656D2E546872656164696E670053797374656D2E52756E74696D652E56657273696F6E696E670053716C537472696E67005265674578436F6D70696C65644D61746368005265674578436F6D70696C656449734D617463680050757368004765745265676578537461636B005F737461636B00417363656E7469732E526567457853514C2E646C6C005265676578506F6F6C006765745F4974656D0053797374656D0053756D0053797374656D2E5265666C656374696F6E004D61746368436F6C6C656374696F6E0047726F7570436F6C6C656374696F6E007061747465726E00547279506F70005265674578436F6D70696C65644D6174636847726F7570005265674578436F6D70696C65644D61746368657347726F75700067726F75700053797374656D2E4C696E7100436C656172004D6963726F736F66742E53716C5365727665722E536572766572002E63746F72002E6363746F72007374720053797374656D2E446961676E6F73746963730053797374656D2E52756E74696D652E496E7465726F7053657276696365730053797374656D2E52756E74696D652E436F6D70696C6572536572766963657300446562756767696E674D6F646573005265674578436F6D70696C65644D6174636865730053797374656D2E446174612E53716C54797065730053797374656D2E546578742E526567756C617245787072657373696F6E730053797374656D2E436F6C6C656374696F6E730052656765784F7074696F6E73006765745F47726F757073006765745F53756363657373004F626A6563740053656C656374005265674578436F6D70696C656453706C6974007265706C6163656D656E7400496E6372656D656E740053797374656D2E436F6C6C656374696F6E732E436F6E63757272656E74006765745F436F756E74005265674578526573657445786563436F756E7400526567457845786563436F756E74005F65786563436F756E74005265674578436163686564436F756E74005265674578436F6D70696C65645265706C616365436F756E7400636F756E74004361737400696E7075740046696C6C526F7700726F7700696E64657800506F6F6C6564526567657800546F417272617900000100004D158B86B1DCE5429EE8D0A265257E4A00042001010803200001052001011111042001010E04200101020B151245020E15124901120C0B15126D020E15124901120C052002011C180E20021301130015126D02130013010A070215124901120C120C0500010810080615124901120C06200102101300050702120C0205200112710E03200002050702120C0E0520020E0E0E0620030E0E0E08060702120C12590520011D0E0E0400010E0E0320000E070703120C125D0E052001125D0E03200008052001127108052000128089062001128081080C10010115128091011E001259040A0112710715126D0212710E1910020215128091011E0115128091011E0015126D021E001E01050A0212710E0D1001011D1E0015128091011E00030A010E0807031214120C12591015126D02151175020E15124901120C08121001020815128091011E0015126D021E00080D0A01151175020E15124901120C072002010E1180950520010113000B151175020E15124901120C042000130108B77A5C561934E08980A00024000004800000940000000602000000240000525341310004000001000100FB9E4120118BC09271D4E040E3E458EC36CA202C6BD68AC96BB205FEAB82016B9F0060CF3B7C48FE32D100E6665381CA72EE115798079CB3ABF0C1914FF04590733A8B23E4E5103C532DF7D32E241E4D6170E06675240D008955E661AB9A7DA815D6E3086CE112FF90392E84F58EED4454439083B670906374EFE5B9B1938BB60C06151245020E15124901120C04061F4D08070615124901120C030612100C0615126D020E15124901120C080615126D0212710E110615126D02151175020E15124901120C080206080300000109000115124901120C0E050001120C0E070002011C101151050002020E0E0600030E0E0E0E0700040E0E0E0E0806000212590E0E0500020E0E0E0600030E0E0E080700040E0E0E080807000312590E0E08030000080A2002010E15124901120C09200115124901120C0E0520010E12710E200108151175020E15124901120C0801000800000000001E01000100540216577261704E6F6E457863657074696F6E5468726F7773010801000200000000000D010008526567457853514C000056010051436F6C6C656374696F6E206F662052656745782066756E6374696F6E7320746F2075736520696E204D5353514C202D2066756E6374696F6E732075736520526567457820436F6D70696C6564206D6F646500000501000000001F01001A417363656E74697320436F72706F726174696F6E2C20496E632E000017010012436F7079726967687420C2A920203230323000002901002433323930653164342D643931642D346635382D623636652D37383936346665333330653600000C010007312E302E302E3100004D01001C2E4E45544672616D65776F726B2C56657273696F6E3D76342E362E310100540E144672616D65776F726B446973706C61794E616D65142E4E4554204672616D65776F726B20342E362E31240100020054020F497344657465726D696E69737469630154020949735072656369736501640100040054020F497344657465726D696E69737469630154020949735072656369736501540E1146696C6C526F774D6574686F644E616D650746696C6C526F77540E0F5461626C65446566696E6974696F6E11535452204E56415243484152284D41582904010000000000008262D332BF7686D5E713B473F22E45BE5E7F25DAF2459EF2E137E2CB986C2F1594E72FDEAAC4B0BCDBBD6F1475FE2DC87D9DFF4D052758C2DD8781A045683D17CCC7085762768A9266A5D78F5EA20D790CF6A3CEF3D759F29D4028DD15373DAE3B087673944872EE3847C9D4504AFA12BDF4C24F220BE67E1290F42EAFD9CE4B000000009ADF58AC00000000020000004D000000A0380000A01A0000000000000000000000000000100000000000000000000000000000005253445301F09E4A51710B478EB4D7FA94C12B3601000000583A5C4465765C6D7373716C2D72656765785C6F626A5C52656C656173655C417363656E7469732E526567457853514C2E706462001539000000000000000000002F39000000200000000000000000000000000000000000000000000021390000000000000000000000005F436F72446C6C4D61696E006D73636F7265652E646C6C0000000000000000FF25002000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058400000100400000000000000000000100434000000560053005F00560045005200530049004F004E005F0049004E0046004F0000000000BD04EFFE00000100000001000100000000000100010000003F000000000000000400000002000000000000000000000000000000440000000100560061007200460069006C00650049006E0066006F00000000002400040000005400720061006E0073006C006100740069006F006E00000000000000B00470030000010053007400720069006E006700460069006C00650049006E0066006F0000004C0300000100300030003000300030003400620030000000BC005200010043006F006D006D0065006E0074007300000043006F006C006C0065006300740069006F006E0020006F0066002000520065006700450078002000660075006E006300740069006F006E007300200074006F002000750073006500200069006E0020004D005300530051004C0020002D002000660075006E006300740069006F006E0073002000750073006500200052006500670045007800200043006F006D00700069006C006500640020006D006F0064006500000056001B00010043006F006D00700061006E0079004E0061006D0065000000000041007300630065006E00740069007300200043006F00720070006F0072006100740069006F006E002C00200049006E0063002E00000000003A0009000100460069006C0065004400650073006300720069007000740069006F006E000000000052006500670045007800530051004C0000000000300008000100460069006C006500560065007200730069006F006E000000000031002E0030002E0030002E00310000004C001600010049006E007400650072006E0061006C004E0061006D006500000041007300630065006E007400690073002E0052006500670045007800530051004C002E0064006C006C0000004800120001004C006500670061006C0043006F007000790072006900670068007400000043006F0070007900720069006700680074002000A90020002000320030003200300000002A00010001004C006500670061006C00540072006100640065006D00610072006B00730000000000000000005400160001004F0072006900670069006E0061006C00460069006C0065006E0061006D006500000041007300630065006E007400690073002E0052006500670045007800530051004C002E0064006C006C000000320009000100500072006F0064007500630074004E0061006D0065000000000052006500670045007800530051004C0000000000340008000100500072006F006400750063007400560065007200730069006F006E00000031002E0030002E0030002E003100000038000800010041007300730065006D0062006C0079002000560065007200730069006F006E00000031002E0030002E0030002E0031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000C000000443900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
DECLARE @hash varbinary(64);

SELECT @hash = HASHBYTES('SHA2_512', @asmBin);

IF EXISTS(SELECT * from sys.trusted_assemblies
	  	  WHERE description = 'Ascentis.RegExSql')
BEGIN
	DECLARE @UnTrustAssembliesCmd nvarchar(max) = '';

	SELECT @UnTrustAssembliesCmd = @UnTrustAssembliesCmd + 'EXEC sys.sp_drop_trusted_assembly @hash = ' + CONVERT(varchar(max), hash, 1) + ';' 
	FROM sys.trusted_assemblies
	WHERE description = 'Ascentis.RegExSql';

	EXEC sp_executesql @UnTrustAssembliesCmd
END

EXEC sys.sp_add_trusted_assembly @hash = @hash, @description = @clrName;

CREATE ASSEMBLY [Ascentis.RegExSQL]
FROM @asmBin
WITH PERMISSION_SET = UNSAFE
GO

CREATE FUNCTION RegExIsMatch( 
  @input nvarchar(max),
  @pattern nvarchar(max)  
)
RETURNS bit EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledIsMatch
GO

CREATE FUNCTION RegExMatch( 
  @input nvarchar(max),
  @pattern nvarchar(max)  
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatch
GO

CREATE FUNCTION RegExMatchIndexed( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @index int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchIndexed
GO

CREATE FUNCTION RegExMatchGroup( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @group int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroup
GO

CREATE FUNCTION RegExMatchGroupIndexed( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @group int,
  @index int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchGroupIndexed
GO

CREATE FUNCTION RegExReplace( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @replacement nvarchar(max)
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplace
GO

CREATE FUNCTION RegExReplaceCount( 
  @input nvarchar(max),
  @pattern nvarchar(max),
  @replacement nvarchar(max),
  @count int
)
RETURNS nvarchar(max) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledReplaceCount
GO

CREATE FUNCTION RegExSplit(
	@input nvarchar(max),
	@pattern nvarchar(max)
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledSplit
GO

CREATE FUNCTION RegExEscape(
	@input nvarchar(max)
)
RETURNS NVARCHAR(MAX) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledEscape
GO

CREATE FUNCTION RegExUnescape(
	@input nvarchar(max)
)
RETURNS NVARCHAR(MAX) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledUnescape
GO

CREATE FUNCTION RegExMatches(
	@input nvarchar(max),
	@pattern nvarchar(max)
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatches
GO

CREATE FUNCTION RegExMatchesGroup(
	@input nvarchar(max),
	@pattern nvarchar(max),
	@group int
)
RETURNS TABLE (ITEM NVARCHAR(MAX)) EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCompiledMatchesGroup
GO

CREATE FUNCTION RegExCachedCount()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExCachedCount
GO

CREATE FUNCTION RegExClearCache()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExClearCache
GO

CREATE FUNCTION RegExExecCount()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExExecCount
GO

CREATE FUNCTION RegExResetExecCount()
RETURNS INT EXTERNAL NAME [Ascentis.RegExSQL].RegExCompiled.RegExResetExecCount
GO
