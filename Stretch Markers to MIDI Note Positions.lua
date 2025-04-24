---------------------------------------------------Based on X-Raym's snap stretch marker Under Mouse to Edit cursor. Big thanks to him


moveEditCurLeftSlightly = reaper.NamedCommandLookup('_XEN_MOVE_EDCUR64THLEFT')
ItemToStretchMarker = reaper.NamedCommandLookup('_9064272d0c45828cec03583f54879d02')
SelTrackToggle = reaper.NamedCommandLookup('_SWS_TOGSAVESEL')
SaveEditCursor = reaper.NamedCommandLookup('_BR_SAVE_CURSOR_POS_SLOT_13')
RestoreEditCursor = reaper.NamedCommandLookup('_BR_RESTORE_CURSOR_POS_SLOT_13')
SaveNoteSelection = reaper.NamedCommandLookup('_BR_ME_SAVE_NOTE_SEL_SLOT_13')
RestoreNoteSelection = reaper.NamedCommandLookup('_BR_ME_RESTORE_NOTE_SEL_SLOT_13')
ProjMarkerToEditCursor = reaper.NamedCommandLookup('_BR_CLOSEST_PROJ_MARKER_EDIT')


origEDCPosition = reaper.GetCursorPosition()

midieditor=reaper.MIDIEditor_GetActive()
teak=reaper.MIDIEditor_GetTake(midieditor)

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1) -- Prevent UI refreshing. Uncomment it only if the script works.


selMediaItemCount = reaper.CountSelectedMediaItems(0)
reaper.Main_OnCommand(SaveEditCursor,0) 
reaper.MIDIEditor_OnCommand(midieditor,SaveNoteSelection)
reaper.MIDIEditor_OnCommand(midieditor,40214) ------unselect all MIDI


for z=0, selMediaItemCount-1 do


if z == 0 then
  reaper.Main_OnCommand(41173,0) ----cursor to Start of Items
else
  reaper.Main_OnCommand(40417,0) -----select and move to Next Item
end

SavedStretchMarkerItem = reaper.GetSelectedMediaItem(0,0)
SavedStretchMarkerItemTake = reaper.GetActiveTake(SavedStretchMarkerItem)
countMarkers = reaper.GetTakeNumStretchMarkers( SavedStretchMarkerItemTake )
retvil, notes, ccs, sysex = reaper.MIDI_CountEvts(teak)


stretchMarkerPositions = {}
stretchMarkerSourcePositions = {}
stretchMarkerID = {}
stretchMarkerPositionsNoEDC = {}
stretchMarkerSourcePositionsNoEDC = {}

reaper.Main_OnCommand(41173,0) ----cursor to Start of Items
reaper.Main_OnCommand(moveEditCurLeftSlightly,0)


item = reaper.GetMediaItemTake_Item(SavedStretchMarkerItemTake)
item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
rate = reaper.GetMediaItemTakeInfo_Value(SavedStretchMarkerItemTake, "D_PLAYRATE")


for k=0, countMarkers-1 do -----------------------------------------------build stretch marker positions table
    retvul,  posi,  srcposi = reaper.GetTakeStretchMarker(SavedStretchMarkerItemTake, k)
    if retvul ~= -1 then
      table.insert(stretchMarkerID, k)
      reaper.Main_OnCommand(41860,0)--NextStretchMarker
      stretchCurrent = reaper.GetCursorPosition()
      table.insert(stretchMarkerPositions, stretchCurrent)
      strsrc = (stretchCurrent - item_pos)*rate
      table.insert(stretchMarkerSourcePositions, strsrc)
      table.insert(stretchMarkerPositionsNoEDC, posi)
      table.insert(stretchMarkerSourcePositionsNoEDC, srcposi)
    end
end


reaper.Main_OnCommand(RestoreEditCursor,0)


countstretchMarkerID = #stretchMarkerID
countstretchMarkerPositions = #stretchMarkerPositions
countstretchMarkerSourcePositions = #stretchMarkerSourcePositions


remainingNotes = {}

for k = 1, notes do
    reaper.MIDIEditor_OnCommand(midieditor,40413) ----- select next note
    restoredNotePosition = reaper.GetCursorPosition()
    table.insert(remainingNotes, restoredNotePosition)
end


hosh = {}
remainingNotesUniq = {}

for _,v in ipairs(remainingNotes) do
   if (not hosh[v]) then
       remainingNotesUniq[#remainingNotesUniq+1] = v -- make channels copy table Unique
       hosh[v] = true
   end
end

table.sort(remainingNotesUniq)


lastnoteStartPosition = reaper.GetCursorPosition()
reaper.MIDIEditor_OnCommand(midieditor,40873) ------ end of selected events in active MIDI media item
lastnoteEndPosition = reaper.GetCursorPosition()
reaper.MIDIEditor_OnCommand(midieditor,40214) ------ deselect all MIDI


reaper.SetEditCurPos(origEDCPosition, true, true)


markersWithinNoteRange={}
remainingMarkers={}
for t=1, #stretchMarkerPositions do
  if stretchMarkerPositions[t] <= lastnoteEndPosition then
    table.insert(markersWithinNoteRange, stretchMarkerID[t])
  end
  if stretchMarkerPositions[t] >= remainingNotes[1] then
    table.insert(remainingMarkers, stretchMarkerID[t])
  end
end


remainingMarkersPositions = {}
for f=1, #remainingMarkers  do
      stretchPos = stretchMarkerPositions[remainingMarkers[f]]
      table.insert(remainingMarkersPositions, stretchPos)
end



if #remainingNotesUniq < #remainingMarkers then loopCount=#remainingNotesUniq else loopCount=#remainingMarkers end

DiffsTable={}
srcPosers={}
srcComposers={}
srcComposersProjectTime={}
srcPosersProjectTime={}
whichIDActual={}
for q=1, loopCount do --------------------------------------------------------------The Main
        notePos = remainingNotesUniq[q]
        stretchPos = stretchMarkerPositions[q]
        posDiff = notePos - stretchPos
        srcDiff = posDiff*rate
        table.insert(DiffsTable, posDiff)
        

      srcNotePos = (notePos - item_pos)*rate
      srcStretchPos = (stretchPos - item_pos)*rate
      stretchPosDiffLaterNotes = stretchPos + posDiff
      srcStretchPosDiff = (stretchPosDiffLaterNotes - item_pos)*rate
      notePosDiffLaterNotes = notePos + posDiff
      srcNotePosDiff = ((notePos+notePosDiffLaterNotes) - item_pos)*rate
      
        
        if posDiff > 0 then --------- if stretching forward

          for x=#stretchMarkerPositions, q+1, -1  do  ------ delete then reinsert all subsequent stretch markers with their new offsets, starting from last
            reaper.DeleteTakeStretchMarkers(SavedStretchMarkerItemTake, stretchMarkerID[x])
            stretchPosNu = stretchMarkerPositions[x]
            srcStretchPosNu = (stretchPosNu - item_pos)*rate
            stretchPosDiffLaterNotesNu = stretchPosNu + posDiff
            srcStretchPosDiffNu = (stretchPosDiffLaterNotesNu - item_pos)*rate
            whichStretchMarkerInsert = reaper.SetTakeStretchMarker(SavedStretchMarkerItemTake, -1, stretchMarkerSourcePositionsNoEDC[x]+srcDiff, stretchMarkerSourcePositionsNoEDC[x])
            whichStretchMarkerDeleteNewPosition = srcStretchPosNu+srcDiff
            table.insert(whichIDActual, stretchMarkerID[x])
            table.insert(srcComposers, srcStretchPosNu+srcDiff)
            table.insert(srcComposersProjectTime, srcStretchPosNu+srcDiff)
            penult = srcComposers[#srcComposers-1]
            penultOrig = stretchMarkerPositions[x+1]
          end
          
        lastDeleted = reaper.DeleteTakeStretchMarkers(SavedStretchMarkerItemTake, stretchMarkerID[q])
        lastDeletedID = stretchMarkerID[q]
        whichStretchMarkerNote = reaper.SetTakeStretchMarker(SavedStretchMarkerItemTake, -1, srcNotePos,stretchMarkerSourcePositionsNoEDC[q])
        table.insert(srcPosers,srcNotePos)   
        table.insert(srcPosersProjectTime,srcNotePos+item_pos)   
        whichStretchMarkerNoteNewPosition = srcNotePos        
        
        elseif posDiff < 0 then  --- if stretching backward
        
        lastDeleted = reaper.DeleteTakeStretchMarkers(SavedStretchMarkerItemTake, stretchMarkerID[q])
        lastDeletedID = stretchMarkerID[q]
        whichStretchMarkerNote = reaper.SetTakeStretchMarker(SavedStretchMarkerItemTake, -1, srcNotePos,stretchMarkerSourcePositionsNoEDC[q])
        table.insert(srcPosers,srcNotePos)   
        table.insert(srcPosersProjectTime,srcNotePos+item_pos)   
        whichStretchMarkerNoteNewPosition = srcNotePos
        
        for x=q+1, #stretchMarkerPositions  do ------ delete then reinsert all subsequent stretch markers with their new offsets, starting from first
            reaper.DeleteTakeStretchMarkers(SavedStretchMarkerItemTake, stretchMarkerID[x])
            stretchPosNu = stretchMarkerPositions[x]
            srcStretchPosNu = (stretchPosNu - item_pos)*rate
            stretchPosDiffLaterNotesNu = stretchPosNu + posDiff
            srcStretchPosDiffNu = (stretchPosDiffLaterNotesNu - item_pos)*rate
            whichStretchMarkerInsert = reaper.SetTakeStretchMarker(SavedStretchMarkerItemTake, -1, stretchMarkerSourcePositionsNoEDC[x]+srcDiff, stretchMarkerSourcePositionsNoEDC[x])
            whichStretchMarkerInsertNewPosition = srcStretchPosNu+srcDiff
            table.insert(whichIDActual, stretchMarkerID[x])
            table.insert(srcComposers, srcStretchPosNu+srcDiff)
            table.insert(srcComposersProjectTime, srcStretchPosNu+srcDiff)
            penult = srcComposers[x-1]
            penultOrig = stretchMarkerPositions[#stretchMarkerPositions-1]
          end
          
          else 
          
          bingbing = "yes"
          
          break
          
                  
          end

end
end 


reaper.MIDIEditor_OnCommand(midieditor,RestoreNoteSelection)

reaper.Undo_EndBlock("Snap stretch markers to MIDI", -1)

reaper.PreventUIRefresh(-1) -- Restore UI Refresh. Uncomment it only if the script works.

reaper.SetEditCurPos(origEDCPosition, true, true)
