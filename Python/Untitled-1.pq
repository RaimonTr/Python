//Modifico "Origen" para que funcione tanto si lo usa Santi como yo
    Origen =
        if User = "ES18434970X" then
            let
                Origen2 = Folder.Contents("C:/Users/" & User & "/OneDrive - Enel Spa/Reclamaciones"),
                #"Filas filtradas" = Table.SelectRows(Origen2, let latest = List.Max(Origen[Date created]) in each [Date created] = latest),
                CSV_File = #"Filas filtradas"{[Name="RECLA_CRM_RCOB_CIRIMP_250923.TXT"]}[Name],
                Import_CSV = Csv.Document(File.Contents("C:\Users\es18434970x\OneDrive - Enel Spa\Reclamaciones\" & CSV_File),[Delimiter="$", Columns=14, Encoding=65001, QuoteStyle=QuoteStyle.None])
 
        else
            Csv.Document(
                File.Contents("\\\\enelint.global\\es\\ESP_SCE\\ESPSEV01FS43\\sced02\\CAMPCOM\\CIRIMP\\RECLA_CRM_RCOB_CIRIMP.TXT"),
                [Delimiter="$", Columns=14, Encoding=65001, QuoteStyle=QuoteStyle.None]
            ),