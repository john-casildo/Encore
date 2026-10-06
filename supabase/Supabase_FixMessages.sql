-- =============================================================================
-- Encore – Fix messages table
-- Run in Supabase SQL Editor.
-- Makes rental_id nullable so conversations that are NOT tied to a specific
-- rental can still send messages (the app never passes rental_id).
-- =============================================================================

ALTER TABLE public.messages ALTER COLUMN rental_id DROP NOT NULL;

-- Also add a missing UPDATE policy so read-receipts can be set later.
DROP POLICY IF EXISTS "messages_update_participant" ON public.messages;
CREATE POLICY "messages_update_participant" ON public.messages
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = messages.conversation_id
              AND (c.renter_id = auth.uid() OR c.host_id = auth.uid())
        )
    );

-- =============================================================================
-- Done. Run this before testing the messaging feature.
-- =============================================================================
