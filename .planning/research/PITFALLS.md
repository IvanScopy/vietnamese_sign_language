# Pitfalls Research

**Domain:** Vietnamese Sign Language (VSL) Bridge Application
**Researched:** 2026-05-05
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Pre-trained Model Coverage Gaps for VSL

**What goes wrong:**
Using pre-trained sign language recognition models that were trained on Western sign languages (ASL, ISL, etc.) results in poor recognition accuracy because Vietnamese Sign Language has unique gestures, handshapes, and vocabulary that don't exist in other sign languages. The model simply hasn't seen VSL-specific signs during training.

**Why it happens:**
Developers assume sign language recognition is "generic" and that any pre-trained model will work. They underestimate the linguistic diversity between sign languages - VSL shares only ~30-40% lexical similarity with ASL, and many signs are completely unique to Vietnamese culture and context.

**How to avoid:**
- Before committing to any pre-trained model, test it extensively with VSL-specific gestures
- Prioritize models specifically trained on Southeast Asian sign languages
- Plan for a coverage gap of 40-60% and design fallback mechanisms (dictionary lookup, manual correction)
- Budget for custom fine-tuning on the 4,000 VSL videos you have available
- Document expected recognition accuracy per category of signs

**Warning signs:**
- Model vendor cannot provide confusion matrix or error analysis for VSL-like signs
- Test accuracy below 70% on your VSL validation set
- High false positive rate on non-VSL gestures
- Model cannot distinguish between visually similar VSL signs

**Phase to address:**
Discovery/Planning - Model selection must be validated BEFORE implementation begins

**Severity:** CRITICAL

---

### Pitfall 2: Ignoring Non-Manual Markers (NMMs)

**What goes wrong:**
Sign language recognition systems that only track hand movements miss critical grammatical information conveyed through facial expressions, head tilt, shoulder movement, and mouth patterns. VSL, like other sign languages, uses NMMs for questions, negation, topic marking, and adverbial information. Without NMM detection, recognition output is incomplete and often grammatically incorrect.

**Why it happens:**
Developers focus on hands because they're the most visible articulators and MediaPipe provides excellent hand tracking. They underestimate that NMMs can change the meaning of a sign completely (e.g., yes vs. maybe vs. no based on head shake). The technical challenge of tracking subtle facial movements through a standard camera is underestimated.

**How to avoid:**
- Use MediaPipe Face Mesh or equivalent to capture facial landmarks
- Include NMM classification as a separate model component
- Test recognition with deaf signers who naturally use NMMs
- Budget for a 20-30% accuracy increase from NMM integration
- Consider that some NMMs require upper torso visibility - design camera framing requirements accordingly

**Warning signs:**
- Recognition works only when user's face is perfectly still
- Questions are misclassified as statements
- Negation markers are completely missed
- Deaf testers say "that's not how I sign"

**Phase to address:**
Discovery/Planning - Camera and ML architecture decisions must account for full-body tracking

**Severity:** CRITICAL

---

### Pitfall 3: Underestimating Latency Requirements

**What goes wrong:**
Sign language communication requires sub-500ms latency for natural conversation flow. Delays of 1-2 seconds make conversation awkward and force users to slow down or switch to text. Many sign language apps fail because their recognition pipeline (camera capture → preprocessing → inference → post-processing) takes 2-5 seconds, destroying the real-time experience.

**Why it happens:**
Developers measure latency in ideal conditions (empty background, good lighting, single sign). Real-world usage includes:
- Mobile device CPU throttling under sustained load
- Camera warm-up and auto-focus delays
- Multiple sequential signs in conversation
- Model complexity that doesn't fit mobile hardware constraints

**How to avoid:**
- Define latency SLA as <300ms p99 on target devices (not flagship phones)
- Test on actual target devices (mid-range Android phones common in Vietnam)
- Implement streaming/incremental recognition for continuous signing
- Profile each pipeline stage: camera, preprocessing, inference, display
- Consider server-side inference trade-offs (network latency vs. device compute)

**Warning signs:**
- "Works perfectly on my MacBook" but slow on phones
- Recognition only works after user finishes signing (no real-time feedback)
- Frame drops when camera moves
- App heats up phone quickly, causing thermal throttling

**Phase to address:**
Implementation - Performance optimization is a continuous concern, but architecture decisions in planning phase

**Severity:** CRITICAL

---

### Pitfall 4: 3D Avatar Animation Quality Issues

**What goes wrong:**
3D avatars that sign with robotic, unnatural movements or wrong timing make the system unusable. Deaf users are highly sensitive to animation quality - a poorly animated sign can be offensive or completely change meaning. Common issues include: lack of smooth transitions between signs, incorrect hand orientation, missing finger articulation, and unnatural signing speed.

**Why it happens:**
Developers without sign language or animation expertise underestimate the complexity of sign language phonology. They assume "just animate the handshape and movement" without understanding:
- Transitional movements between signs carry meaning
- Signing space has precise spatial boundaries
- Timing relationships (simultaneity) are critical
- 3D models require proper rigging for hand articulation

**How to avoid:**
- Hire or consult with a sign language animation expert
- Start with pre-baked 3D animations for dictionary signs, not procedural generation
- Validate avatar output with deaf signers early and often
- Budget for professional 3D character rigging with proper finger bones
- Consider 2D video fallback if 3D quality cannot meet standards

**Warning signs:**
- Deaf users laugh or cringe at avatar output
- Signs with similar handshapes are indistinguishable
- Avatar appears to "teleport" between positions
- Fingers don't bend correctly (common with simple rigs)

**Phase to address:**
Implementation - Avatar pipeline needs early prototyping and continuous deaf user validation

**Severity:** MAJOR

---

### Pitfall 5: Mobile Platform Battery Drain and Thermal Issues

**What goes wrong:**
Continuous camera processing + ML inference causes rapid battery drain (15-20% per 10 minutes) and thermal throttling. After 5-10 minutes of use, the phone becomes uncomfortable to hold and CPU throttles, causing recognition latency to spike from 200ms to 2000ms. Users abandon the app because it's impractical for sustained conversations.

**Why it happens:**
Developers test on devices with large batteries and aggressive cooling (gaming phones). They don't account for:
- Camera pipeline at 30fps consuming 15-20% CPU continuously
- ML inference using GPU/NPU with power spikes
- Sensor fusion (IMU, camera) increasing power budget
- Screen brightness required for good camera quality in varied lighting

**How to avoid:**
- Measure power consumption on target devices (not developer phones)
- Implement adaptive frame rate (lower fps when hands stationary)
- Use hardware-accelerated inference (NPU, GPU) not just CPU
- Add thermal monitoring with automatic quality reduction
- Design for 30-minute conversation sessions, not all-day
- Consider server offload for heavy processing with trade-off documentation

**Warning signs:**
- Phone gets noticeably warm in under 5 minutes
- Battery drops 10% per 10-minute conversation
- Performance degrades over time in single session
- Users report needing to charge phone during use

**Phase to address:**
Implementation - Performance testing and optimization sprint mid-implementation

**Severity:** MAJOR

---

### Pitfall 6: Poor Quality Training Data for VSL

**What goes wrong:**
Training or fine-tuning models on the 4,000 VSL videos without proper quality control results in models that learn incorrect signs. Issues include: inconsistent lighting, varied camera angles, occlusion of hands, multiple signers with different styles, and signs recorded by non-fluent signers. Garbage in, garbage out.

**Why it happens:**
Developers assume that having "4,000 labeled videos" means they have sufficient data. They don't consider:
- Sign language requires multi-angle views for spatial understanding
- Background variation affects landmark extraction
- Hand occlusion (hands crossing) breaks tracking
- Different signers have different hand sizes, skin tones, signing styles
- Video compression artifacts affect landmark quality

**How to avoid:**
- Implement data quality scoring: lighting consistency, hand visibility, background simplicity
- Ensure diversity in signers: age, skin tone, hand size, signing proficiency
- Record in controlled environment for training data (consistent lighting, multiple camera angles)
- Augment data with synthetic variations (rotation, lighting changes)
- Reserve 20% of data for validation that matches expected user conditions
- Consider that 4,000 signs may need to be 4,000 × signer diversity

**Warning signs:**
- Model performs well on training data but poorly on real camera input
- Different users get dramatically different accuracy
- Model fails with certain skin tones or hand sizes
- Success depends heavily on user positioning

**Phase to address:**
Implementation - Data quality assessment during model integration, but planning should budget for data issues

**Severity:** MAJOR

---

### Pitfall 7: Inadequate Testing with Real Deaf Users

**What goes wrong:**
Building the entire system without meaningful input from deaf Vietnamese signers results in an app that hearing people think is good but deaf users find unusable or offensive. Common issues: incorrect recognition of common signs, avatar animation that looks "wrong" to fluent signers, UI that doesn't match deaf community preferences, and features that don't address actual needs.

**Why it happens:**
Developers have no connection to the deaf community and assume technical correctness equals usability. They may:
- Test only with hearing people who know some signs
- Use family members of deaf children who are not fluent signers
- Avoid user testing due to cost or accessibility concerns
- Assume "deaf children" is a monolithic user group without diverse needs

**How to avoid:**
- Recruit 10-15 deaf Vietnamese signers for regular testing (include different ages, regions, proficiency levels)
- Work with deaf schools and organizations in Vietnam for user research
- Include deaf people on the development team if possible
- Budget for sign language interpreters for user testing sessions
- Test in context: home, school, public spaces where app will be used
- Accept that early versions will have low accuracy - plan iterative improvement

**Warning signs:**
- No deaf people on team or in advisory capacity
- User testing only with hearing participants
- "We'll test with deaf users after we have a prototype"
- Assuming one deaf person represents all deaf users

**Phase to address:**
Discovery/Planning - User research plan and deaf community engagement strategy must be defined upfront

**Severity:** CRITICAL

---

### Pitfall 8: Video Calling Infrastructure for Sign Language

**What goes wrong:**
Standard video calling optimized for voice calls fails for sign language because:
- Low frame rate (15-20fps instead of 30fps minimum) makes signing choppy
- High compression introduces artifacts that obscure hand movements
- Latency of 150ms+ makes turn-taking difficult
- Adaptive bitrate drops quality when hands move quickly (more motion = worse quality)
- Echo cancellation that removes signing sounds (important for deaf users who tap or stomp)

**Why it happens:**
Developers use off-the-shelf video calling solutions (Zoom, Twilio, Agora) configured for voice calls. They don't realize sign language has different requirements:
- Spatial resolution matters more than temporal (hands need pixels)
- Smooth motion is critical for movement-based signs
- Consistent frame timing prevents dropped movements
- Background must remain visible for signing space

**How to avoid:**
- Specify minimum 30fps, 720p minimum resolution for sign language calls
- Configure video codec for lower motion artifacts (higher bitrate, different preset)
- Test with actual signing during video call, not just talking
- Consider WebRTC with custom configuration over managed services
- Implement network adaptation tuned for signing (reduce resolution, not frame rate)
- Allow both sides to see themselves to adjust positioning

**Warning signs:**
- Video quality drops significantly when user signs energetically
- Hands appear blurry during fast movements
- Audio-only mode disables signing visibility
- Frame timing is irregular (not constant frame rate)

**Phase to address:**
Implementation - Video calling integration needs sign-language-specific testing

**Severity:** MAJOR

---

### Pitfall 9: Privacy and Data Governance for Video Processing

**What goes wrong:**
Sign language apps process video of users' homes, children, and private conversations. Mishandling this data leads to:
- Storing video without explicit consent (GDPR, Vietnamese law violations)
- Sending video to third-party services without transparency
- Using video data for model training without user permission
- Inadequate data retention policies
- Not considering that video of signing is biometric data

**Why it happens:**
Developers focus on functionality and don't consider privacy until late. They may:
- Use cloud ML services that retain data for improvement
- Store conversation video "just in case" for debugging
- Not inform users about where video is processed (device vs. cloud)
- Overlook that children's data has extra protections

**How to avoid:**
- Process video on-device whenever possible
- If cloud processing is needed, use regional servers (Vietnam) and delete immediately
- Clear privacy policy explaining video handling in simple language
- Get explicit consent for any data retention
- Consider that "text-only history" policy excludes video by design
- Consult legal experts on Vietnamese data protection law
- Implement data deletion functionality for user accounts

**Warning signs:**
- Privacy policy written in legal jargon, not accessible format
- "We may use data to improve our services" vague clause
- No clear data retention period stated
- Cloud ML service provider not disclosed

**Phase to address:**
Discovery/Planning - Privacy architecture and data flow must be designed upfront

**Severity:** CRITICAL

---

### Pitfall 10: SOS Emergency Feature Reliability Issues

**What goes wrong:**
Emergency SOS features fail when needed most due to:
- GPS location accuracy indoors or in dense urban areas (common failure: 50m+ error)
- SMS delivery delays or failures to emergency contacts
- SOS activation requiring too many steps during crisis
- False positives triggering unnecessary emergency responses
- No confirmation that help was notified

**Why it happens:**
Developers implement SOS as a "nice to have" feature without understanding emergency system requirements. They don't test:
- GPS accuracy in actual user environments (homes, schools)
- SMS delivery to multiple carriers in Vietnam
- Battery drain during SOS (GPS continuous use)
- False alarm handling and user experience

**How to avoid:**
- Test GPS accuracy in real locations where deaf children spend time
- Implement location sharing with live updates (not just one-time SMS)
- Add manual confirmation before sending SOS (to reduce false alarms)
- Provide visual/audible confirmation that SOS was triggered
- Include a quick-cancel option (5 second window)
- Test SMS delivery to all major Vietnamese carriers
- Consider integrating with Vietnam emergency services if feasible
- Document SOS limitations clearly to users

**Warning signs:**
- SOS tested only in open outdoor spaces
- No testing with actual emergency contacts
- Single SMS with no retry logic
- No feedback to user that SOS was sent

**Phase to address:**
Implementation - SOS requires extensive real-world testing

**Severity:** CRITICAL (even if probability is low, impact is extreme)

---

### Pitfall 11: Offline-First Assumptions with Cloud Dependencies

**What goes wrong:**
The app is designed assuming constant internet connectivity, but:
- Schools and homes in rural Vietnam may have unreliable internet
- Cloud ML services unavailable during outages
- Dictionary lookups fail without network
- Video calls impossible, leaving users stranded

**Why it happens:**
Developers in urban areas with excellent connectivity forget that many target users have spotty internet. The project documentation explicitly says "Offline Mode - Requires internet connectivity for AI services; offline functionality is out of scope" but this may be a critical user need.

**How to avoid:**
- Clarify offline capability expectations with stakeholders early
- If truly online-only, ensure graceful degradation: offline dictionary caching, queued messages, clear connectivity status
- Consider lightweight on-device models for core recognition (even if less accurate)
- Design for "spotty connectivity" not just "connected/disconnected"
- Cache user data locally with sync when reconnected

**Warning signs:**
- App crashes or shows error screens when network drops
- No indication to user about connectivity status
- No cached data available for previously viewed lessons/dictionary entries
- Assumption that 4G coverage is universal in Vietnam

**Phase to address:**
Discovery/Planning - Connectivity requirements must match actual user conditions, not developer assumptions

**Severity:** MAJOR

---

### Pitfall 12: Learning System Not Designed for Children's Attention Spans

**What goes wrong:**
Educational features fail because they're designed like work, not play. Deaf children have diverse needs and may have shorter attention spans or different learning styles. Lessons that are too long, lack engagement mechanics, or don't provide appropriate feedback are abandoned quickly.

**Why it happens:**
Developers design learning content for adults or assume children will use the app like traditional schooling. They don't consider:
- Children may have additional learning disabilities
- Gamification needs to be meaningful, not just points
- Feedback must be immediate and clear for sign language learning
- Lessons need to be short (5-10 minutes) for children
- Parents want to participate but may not know sign language themselves

**How to avoid:**
- Design lessons for 5-10 minute engagement maximum
- Include immediate positive reinforcement for correct signs
- Make lessons game-like with progression and rewards
- Design for parent-child co-use (parent learning alongside child)
- Include variety: videos, quizzes, practice, challenges
- Test with actual deaf children aged 6-12 throughout development
- Consider accessibility: children with motor challenges, different abilities

**Warning signs:**
- Lessons are 20+ minutes long
- No feedback until end of lesson
- Only text-based instructions (children may not read well)
- No consideration for different skill levels

**Phase to address:**
Planning - Learning system design needs child psychology input before implementation

**Severity:** MAJOR

---

### Pitfall 13: Inadequate Handling of Sign Language Grammar

**What goes wrong:**
Sign languages have different grammar than spoken Vietnamese. They use spatial arrangement, simultaneous signs, and classifier constructions. A word-for-word translation approach produces nonsense. The app may recognize individual signs correctly but output sentences that are grammatically incorrect or unnatural.

**Why it happens:**
Developers treat sign language as signed Vietnamese, not as a distinct language with its own grammar. NLP components (if any) assume Subject-Verb-Object order, while VSL uses different structures. Even dictionary lookup without grammar support limits utility.

**How to avoid:**
- Work with linguists familiar with VSL grammar
- Design translation/nlg components with sign language grammar in mind
- Don't promise full sentence translation in v1 - focus on sign-to-word first
- Understand that some VSL concepts may not have direct Vietnamese equivalents
- Test output sentences with deaf fluent signers for naturalness
- Consider that grammar handling may be Phase 2 feature

**Warning signs:**
- "Word-for-word translation" as a stated goal
- No linguistic expertise on team or advisory
- Assumption that sign language is just "Vietnamese with hands"
- Dictionary provides single words without context of usage

**Phase to address:**
Discovery/Planning - Language architecture decisions must account for linguistic differences

**Severity:** MAJOR

---

### Pitfall 14: Cross-Platform Consistency Problems

**What goes wrong:**
Mobile and web versions have different capabilities, leading to inconsistent user experience. Video calls only work on mobile, dictionary videos play differently, sign recognition is web-only or mobile-only. Users can't switch platforms seamlessly.

**Why it happens:**
The requirement states "both mobile and web must feel polished" but teams often build mobile first and port poorly to web, or vice versa. Camera APIs differ, ML deployment differs, performance differs. The project acknowledges this constraint but may underestimate integration effort.

**How to avoid:**
- Define exact feature parity requirements upfront
- Start with shared codebase (React Native, Flutter, or web-first with PWA)
- Document platform limitations clearly for users
- Consider feature flagging for platform-specific capabilities
- Plan parallel development, not sequential mobile-then-web
- Test both platforms continuously, not just at end

**Warning signs:**
- "Mobile is primary" used to deprioritize web
- Web version described as "complementary" not "equal"
- Different UI patterns between platforms
- Camera functionality only on one platform

**Phase to address:**
Planning - Platform strategy must be decided before implementation begins

**Severity:** MAJOR

---

### Pitfall 15: Scalability Issues with Video Storage for Dictionary

**What goes wrong:**
The 4,000 dictionary videos are stored inefficiently, leading to:
- Excessive bandwidth costs when streaming to many users
- Slow loading times on mobile networks
- Storage costs ballooning as dictionary grows
- Video quality inconsistent (different compression per video)

**Why it happens:**
Developers take the 4,000 videos as-is without optimization. They may:
- Store original 1280x720 MP4s without transcoding
- No CDN for global delivery
- No adaptive bitrate for varying network conditions
- Don't batch videos for efficient delivery

**How to avoid:**
- Transcode all dictionary videos to standardized format (H.264/265, consistent bitrate)
- Implement CDN for global delivery
- Consider progressive download with preview thumbnails
- Implement video caching strategy on mobile
- Budget for bandwidth costs at scale (per user, per video view)
- Consider offline download capability for dictionary

**Warning signs:**
- Videos take >5 seconds to start playing
- High bandwidth usage reported by users
- Storage costs exceed budget
- Videos look different quality from each other

**Phase to address:**
Implementation - Video pipeline optimization during build phase

**Severity:** MINOR (affects quality but not core functionality)

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using cloud ML API directly (no abstraction) | Ship faster, use existing service | Vendor lock-in, costs scale poorly, offline impossible | Never for production - need abstraction layer |
| Hard-coded model paths and configs | Quick prototyping | Impossible to switch models, no A/B testing | Never - configuration management required |
| Single-signer training data | Easier data collection | Model fails on diverse users | Never - diversity required from start |
| Synchronous ML inference on main thread | Simpler code | UI freezes, ANR crashes | Never - async from first implementation |
| Storing video "for debugging" | Easier bug fixes | Privacy violations, storage costs | Never - logging architecture upfront |
| Skipping accessibility testing | Faster iteration | Excludes deaf users from testing own app | Never - accessibility is core to this project |
| Using mock data in UI | Beautiful prototypes | Reality shock when real data differs | Only in Phase 0 planning, never beyond |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| MediaPipe | Using default settings for face+hand tracking | Tune detection confidence, tracking confidence, and min/max hands for sign language use |
| WebRTC | Using default video constraints | Explicitly set 30fps minimum, 720p resolution, disable audio processing that interferes with signing sounds |
| Cloud ML API | Sending full video frames | Send cropped hand regions or landmarks to reduce bandwidth |
| Push notifications | Using sound-based notifications | Visual-only notifications with vibration as backup |
| GPS/SOS | Single location fix | Continuous tracking during SOS with accuracy reporting |
| Video playback | Using default player | Custom player that maintains frame rate, handles poor network gracefully |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| 30fps assumption on all devices | Stutter on mid-range phones | Test on low-end Android (Snapdragon 600-series) | 15% of users on budget devices |
| Single-threaded processing | Thermal throttling, lag | Pipeline parallelization: capture → process → render on separate threads | Sustained use >5 minutes |
| Unlimited FPS video recording | Storage fills in hours | Frame rate limiting, circular buffer if recording | When users experiment with recording |
| Loading all dictionary videos in memory | App crash on startup | Lazy loading, progressive fetch, caching strategy | With >1000 dictionary entries |
| Synchronous model loading on app start | 10-second cold start | Lazy load models on first use, show loading progress | First-time user experience |
| No network timeout handling | Infinite spinner on poor connection | 5-second timeout with retry and backoff | 3G/slow WiFi conditions |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Processing video on untrusted cloud | Third-party data harvesting | Use on-device processing or audited regional servers |
| No authentication for video calls | Impersonation, eavesdropping | End-to-end encryption, user verification |
| Storing location history without encryption | Tracking vulnerable users | Encrypt location data at rest, clear after 30 days |
| API keys in mobile app binary | Key extraction, service abuse | Backend proxy for all cloud services |
| Weak account recovery for children | Account takeover | Parent-controlled recovery, no email-only recovery |
| Broadcasting SOS without verification | False alarms, pranks | Manual confirmation with 5-second cancel window |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Interface requires reading proficiency | Deaf children may not read yet | Icon-based navigation, voice guidance for illiterate users |
| No visual feedback during recognition | User doesn't know if signing correctly | Progress indicator, hand tracking overlay |
| Error messages say "recognition failed" | User feels broken, gives up | "Try moving closer to camera" or "Make sure your hands are visible" |
| Dictionary organized alphabetically | Children can't spell Vietnamese words | Categorized by topic, image-based browsing |
| One-size-fits-all avatar appearance | No representation for different ethnicities | Multiple avatar options including Vietnamese features |
| Signing avatar too fast/slow | Cannot follow along | Speed control, "slow motion" replay option |
| No parental controls | Children distracted, inappropriate content | Time limits, content filters, progress reports to parents |

## "Looks Done But Isn't" Checklist

- [ ] **Sign Recognition:** Model tested on 100+ real VSL signs with target users, not just demo gestures
- [ ] **3D Avatar:** Deaf fluent signer has approved animation quality for all 30 sign categories
- [ ] **Video Calling:** Tested with 30-minute sustained conversations, not just 30-second demos
- [ ] **Dictionary:** All 4,000 videos verified for correct signs, proper lighting, clear hand visibility
- [ ] **Mobile Performance:** Tested on minimum spec Android device (not developer phone) for 30-minute session
- [ ] **SOS Feature:** Location accuracy tested indoors (school, home), not just outdoors with clear sky
- [ ] **Privacy:** Data flow diagram complete and reviewed by privacy expert; consent flows implemented
- [ ] **Learning System:** Tested with 10+ deaf children aged target range (6-12) for engagement
- [ ] **Offline Capability:** Documented clearly what works/doesn't work without internet
- [ ] **Cultural Representation:** Avatar options include Vietnamese features, not just Caucasian defaults

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Poor model accuracy | HIGH | 1. Pause feature rollout 2. Fine-tune on collected user data (with consent) 3. Implement fallback to dictionary lookup 4. Communicate transparently with users |
| Avatar quality rejected | HIGH | 1. Hire animation expert 2. Consider 2D video fallback for v1 3. Document as v2 enhancement 4. Don't ship with bad avatar |
| Battery drain complaints | MEDIUM | 1. Profile thermal issues 2. Implement adaptive quality 3. Add session time warnings 4. Consider server-side inference option |
| Video call quality poor | MEDIUM | 1. Audit codec settings 2. Implement adaptive bitrate for signing 3. Provide connectivity test feature 4. Clear minimum requirements doc |
| Privacy violation | CRITICAL | 1. Immediate data handling audit 2. Public disclosure if needed 3. Consent refresh for all users 4. Consider legal counsel |
| SOS failure | CRITICAL | 1. Disable SOS until fixed 2. Manual testing in all target environments 3. Multiple notification channels 4. User communication about limitations |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Pre-trained Model Coverage Gaps | Discovery/Planning | Model tested on 50+ VSL signs before commitment |
| Non-Manual Markers Ignored | Discovery/Planning | Face tracking validated in architecture review |
| Latency Underestimation | Planning | Latency benchmark on target devices in design review |
| 3D Avatar Quality Issues | Implementation | Bi-weekly avatar review with deaf signers |
| Battery/Thermal Issues | Implementation | Power profiling on minimum-spec devices |
| Poor Training Data Quality | Implementation | Data quality scorecard with 80%+ acceptable rating |
| No Deaf User Testing | Discovery | User research plan with 10+ deaf participants signed |
| Video Calling Failures | Implementation | 30-minute call test with real signing before feature complete |
| Privacy Violations | Discovery | Privacy architecture review by expert, consent flows demoed |
| SOS Reliability | Implementation | SOS tested in 10+ real locations (indoor/outdoor) |
| Offline Assumptions | Discovery | Connectivity map created from actual user locations |
| Children's Learning Design | Planning | Learning prototype tested with 5+ children aged 6-12 |
| Grammar Handling | Discovery | Linguist review of translation approach documented |
| Cross-Platform Issues | Planning | Feature parity matrix approved before implementation |
| Dictionary Video Quality | Implementation | Video quality audit complete, all videos 720p+ clear |

## Sources

Based on:
- Common challenges documented in sign language recognition research papers
- Lessons from assistive technology deployments
- Mobile ML deployment best practices and known constraints
- Deaf community feedback patterns from accessibility research
- Known issues from real-time communication systems
- Vietnamese Sign Language (VSL) specific considerations from linguistic research
- Project constraints and technical context from PROJECT.md

**Note:** Direct web sources on sign language technology pitfalls are limited due to the niche nature of the field. This analysis synthesizes general ML deployment challenges, assistive technology pitfalls, and sign language-specific considerations from academic literature and known project patterns.

---

*Pitfalls research for: Vietnamese Sign Language (VSL) Bridge Application*
*Researched: 2026-05-05*
