
--3.2 Combining Related Rows (USING DBEAVER SAMPLE DATABASE)
--AND 3.3 Finding Rows in Common Between Two Tables
select *--DISTINCT PlaylistId 
	from PlaylistTrack pt 
join Track t 
	on pt.TrackId = t.TrackId
join Playlist p 
	using(PlaylistId)
order by TrackId 
--select (TrackId+PlaylistId) as sumIDs

--3.4 Retrieving Values from One Table That Do Not Exist in Another
-- (USING DBEAVER SAMPLE DATABASE)
	select ArtistId 
		from Artist a
		except 
		select ArtistId from Album 
		order by ArtistId 
	
	
