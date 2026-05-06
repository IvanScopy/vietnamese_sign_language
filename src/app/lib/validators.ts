import { z } from 'zod'

export const TranscribeSchema = z.object({
  language: z.string().default('vi'),
})

export const SynthesizeSchema = z.object({
  text: z.string().min(1, 'Text is required'),
  language: z.string().default('vi'),
})
