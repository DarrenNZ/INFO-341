--notes
-- question 8 i dont understand.
-- after creating final table the insert that declares them as zero i do not understand.

GO
--Create procedure sp_Assisgment_tWO 
GO
use assignment2;
--Declares what database the stored procedure will run on

drop function dbo.Question1;
drop function dbo.question2;
drop function dbo.Question3;
drop function dbo.Question4;
drop function dbo.Question5;
drop procedure question7;
drop procedure Question_9;
drop procedure Question10;
--drop function dbo.Question6

----=============================================================================== Question 1
--Scalar function that returns the total word count in in essay.
go
CREATE FUNCTION [dbo].[Question1] (@string varchar(8000))
RETURNS SMALLINT  
--scalar returns int value
AS
BEGIN 
	SET @string = LTRIM(RTRIM(ISNULL(@string,''))); 
	IF LEN(@string) = 0 RETURN 0; 
	-- return the difference in length after stripping spaces, this is the word count
	RETURN ((LEN(@string) + 1) - LEN(REPLACE(@string,' ',''))); 
END 

----=============================================================================== Question 2
--scalar computes the total character count of the essay excluding spaces
go
create function dbo.question2 (@string varchar(8000))
returns smallint
--function returns small interger
as
begin
--counts all characters
set @string = len(replace(@string, ' ', ''))
return @string
--returns count of characters
end

----=============================================================================== Question 3
--scalar function scans the essay column for "?", "!" and "." inorder to count the amount of sentences
go
Create FUNCTION Question3(@string varchar(8000))
RETURNS decimal(10,4)  
--scalar returns decimal
AS
BEGIN 
--counts the number of specified characters whithin essay
set @string = sum((LEN(@string) - LEN(REPLACE(@string, '.', '')) + 1) + 
(LEN(@string) - LEN(REPLACE(@string, '?', '')) + 1) + 
(LEN(@string) - LEN(REPLACE(@string, '!', '')) + 1)) 
Return  @string
--returns number of sentences
END


----=============================================================================== Question 4
--scalar function that calculates the number of words and then divides by the amount of letters
--therfore return the average amount of letters per word.
go
CREATE FUNCTION DBO.Question4 (@string varchar(8000))
returns decimal(10,4)
--returns decimal
as begin
declare 
@numwords decimal(10,4), 
@numchar decimal(10,4),
@avg decimal(10,4);
--declares variables to be used in equation
set @numchar = len(replace(@string, ' ', ''));
SET @numwords =((LEN(@string) + 1) - LEN(REPLACE(@string,' ',''))); 
SET @avg = SUM(@numchar/@numwords)
return @avg
--returns a decimal type that is the average letter count for the number of words in essay
end


----=============================================================================== Question 5
--scalar function that returns the average number of words per sentence.
go
Create FUNCTION dbo.Question5(@string varchar(8000))
RETURNS decimal (10,4)
--returns decimal
AS
BEGIN
	Declare @a float,
		    @b float,
			@c float;
			-- declares float values
		set @a =(SELECT (LEN(@string) - LEN(REPLACE(@string, ' ', '')) + 1))
		set @b =(select sum ((LEN(@string) - LEN(REPLACE(@string, '.', '')) + 1)))
		select @c = (@a / @b)
Return  @c
--sets @c to the average number of words depending on the sentence.
END


----=============================================================================== Question 6 
--creates a procedure that calculates the Coleman Liau Index (CLI) ie CLI=0.0588L-0.296S-15.8

drop procedure question6
create procedure question6
as
begin
--creates a table with decimal data types
create table #question6
(
id int,
question1 decimal(10,4),
question2 decimal(10,4), 
question3 decimal(10,4),
CLI decimal(10,4),
[first] decimal(10,4),
[second] decimal(10,4)
);
--inserts in the above table the scalar functions from questions one two and three.
insert into #question6(id, question1, question2, question3, CLI, [first], [second])
select id, question1, question2, question3, 0 as cli, 0 as [first], 0 as [second]
from Essay_score_table 
--sets the columns in accordance with the calulations by updateing the table using the sclar functions from
--question one, two and three.
update #question6 set [first] = (question2*100/question1);
update #question6 set [first] = ([first] * 0.0588);
update #question6 set [second] = (question3 *100/question1);
update #question6 set [second] = ([second] * 0.296);
update #question6 set [CLI] = ([first] - [second]) - 15.8;
--finnaly updates the final awsner into the essay_score_table with the final CLI result.
Update essay_score_table 
set question6 = CLI  
from #question6 T
inner join essay_score_table E on
E.ID = T.ID
--needs to use a join inorder to match the ID so the temp and essay_score_table are able to marry.
end
exec question6

----=============================================================================== Question 7
--creates a procedure that uses a cursor to count the stop words using the full text search engine, taking into account
--multiple occurinces of the stop word within the essay.
CREATE procedure question7
AS
BEGIN
create table #temptable(
ID	INT,
Word_count	INT
);
--above creates procedure and temporary table for the cursor to use.
DECLARE
@word	nvarchar(max)

DECLARE seven_stop_Cursor	
CURSOR FOR SELECT stopword 
FROM sys.fulltext_system_stopwords
--declares cursor and selects the system stopwords.

--Opens cursor and fetches the first stopword for the cursor
OPEN seven_stop_Cursor
FETCH NEXT FROM seven_stop_Cursor INTO @word

	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			FETCH NEXT FROM seven_stop_Cursor INTO @word
		END
		--iteration for the cursor while there is another stopword in the list it will continue to grab them.
CLOSE seven_stop_Cursor
DEALLOCATE seven_stop_Cursor

INSERT INTO #temptable(id, Word_count) 
	SELECT id, (LEN(Essay) - LEN(REPLACE(Essay,@word, ''))) as word_count
	FROM essays
	--inserts the result into the temporary table
	
Update essay_score_table 
set question7 = Word_count
from (Select id, Word_count as Word_count
	FROM #temptable) as t
inner join essay_score_table E on
E.ID = T.ID
 --needs to use a join inorder to match the ID so the temp and essay_score_table are able to marry
END
----=============================================================================== Question 8
--creates a procedure that creates a temorary table to insert into while comparing the words in the essay too the connecting words
-- from the excel file.
drop function question8 
create procedure question8
as
begin
create table #8
(
id int,
word_count int,
essay varchar(8000)
)
--creates table and instatiates data types

insert into #8 (id, word_count, essay)
select id, count(id) as word_count, essay
from essays, ['Connecting words$']
where PATINDEX('%' + ['Connecting words$'].[Above all] + '%', essays.ESSAY) > 0 
or
PATINDEX('%' + '.' + ['Connecting words$'].[Above all] + '.' + '%', essays.ESSAY) > 0 
or
PATINDEX('%' + ',' + ['Connecting words$'].[Above all] + ',' + '%', essays.ESSAY) > 0 
group by ESSAY, ID
order by ID, ESSAY

update Essay_score_table
set Question8 = word_count 
from #8 t
inner join Essay_score_table e on
e.ID = t.id
 --needs to use a join inorder to match the ID so the temp and essay_score_table are able to marry
end
go

----=============================================================================== Question 9 working
--creates stored procedure with temporary table inorder to compute the total amount of sat words using a cursor.
CREATE PROCEDURE Question_9
As
Begin
Create Table #tempTable1(
	ID Int,
	word nvarchar(max),
	Essay nvarchar(max),
	[count] Int
);
--creates a temporary table
Declare @SearchString nvarchar(250),
@x nvarchar(250)
--declaring varaibles for the cursor ie essay and counter
Declare Cursor_9 Cursor
For Select * From ['SAT words$']
--sets the fetchnext within the cursor to select the next sat word from the sat table.
Open Cursor_9

Fetch Next from Cursor_9 into @SearchString

While @@FETCH_STATUS=0
Begin
	If (@SearchString Is Not NUll)
	Begin
	Set @x = N'FORMSOF(INFLECTIONAL,'+ @SearchString +')'
	Insert Into #tempTable1
	Select ID, @x as Word, Essay, 1 as [count] from essays Where Contains(Essay,@x)
	End
	Fetch next from Cursor_9 into @SearchString
End
--interation within the cursor compares the sat word to essay and searches for inflectional forms of the word.
Close Cursor_9

Deallocate Cursor_9
--Select Sum([count]) as Counts From #tempTable1 Group by ID Order by ID ASC

Update essay_score_table 
set question9 = Counts
from (Select id, Sum([count]) as Counts From #tempTable1 Group by ID) as T
inner join essay_score_table E on
E.ID = T.ID
 --needs to use a join inorder to match the ID so the temp and essay_score_table are able to marry
End
Go

----=============================================================================== Question 10
--creates a procedure that calculates the count of universtiy words present within the essay score table by comparing it to 
--the university words that are in the excel file, this inclueds infectional words.
Create procedure question10
as
begin
Create table #ten_connect
(
connect_id int Identity(1,1) primary key,
word_Connect varchar(30),
);--creates temorary table that generates its own unique id
Insert into #ten_connect(word_Connect)
select [abandon ] from ['Words List$'] 
where [abandon ] is not null
--inserts a local copy of the word list
Declare @essay varchar(max),
		@ftsQuery varchar(50);
declare @ten table
(
ID int
--declares variables and a table
)--below declares a cursor that fetches the next word from the temp table that has the university words inserted into it.
Declare ten_cursor Cursor for Select word_connect from #ten_connect 
Open ten_Cursor
Fetch next from ten_cursor 
Into @ftsQuery
While @@FETCH_STATUS = 0
Begin
Insert into @ten
		select ID from essays
		where freetext (Essay, @FtsQuery)
		fetch next
		from ten_cursor
		into @ftsQuery
		End
--while there are still university words in the table the cursor will fetch them and compare them to the @ftsquery using 
--the freetext in the where clause to also search for inflectional forms of the word.
Close ten_cursor
Deallocate ten_cursor
End
--closes and deallocates the cursor once all the rows have been searched.
Go

----================================================================================ Putting into a table to call on
drop table essay_score_table 
create table Essay_score_table
(
ID bigint,
Essay varchar(max),
score bigint,
Question1 as (dbo.Question1(essay)),
Question2 as (dbo.question2(essay)),
Question3 as (dbo.question3(essay)),
Question4 as (DBO.Question4(essay)),
Question5 as (DBO.Question5(essay)),
Question6 decimal (10,4),
Question7 decimal (10,4),
Question8 decimal (10,4),
Question9 decimal (10,4),
Question10 decimal (10,4)
);-- ddl that creates the final table where all of the results are showen. this includes quesions one through ten.
go
insert into Essay_score_table 
select s.id as id, s.essay as essay, s.score as score, 0 as question6, 0 as question7, 0 as question8, 0 as question9, 0 as question10
from dbo.essays s;
go
exec question6;
exec question7;
exec question8;
exec Question_9;
exec Question10;
--executes the stored procedures in order to update the final table.

select * from Essay_score_table
order by id 
--select query retrives all of the information from the final table where question one through ten are stored.
