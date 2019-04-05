' this file contians all the functions related to generating PBKDF2 hasing
' and other supporting functions for the same


'Function       :   AkaMA_PBKDF2
'Params         :   None 
'Return         :   GUID string 
'Description    :   Returns PBDFK2 hashing 
'Below is PBKDF2 derivation process
'
' The PBKDF2 key derivation function has five input parameters:
' DK = PBKDF2(PRF, Password, Salt, c, dkLen)
' where:
'
' PRF is a pseudorandom function of two parameters with output length hLen (e.g. a keyed HMAC)
' Password is the master password from which a derived key is generated
' Salt is a cryptographic salt
' c is the number of iterations desired
' dkLen is the desired length of the derived key
' DK is the generated derived key
' Each hLen-bit block Ti of derived key DK, is computed as follows:
'
' DK = T1 || T2 || ... || Tdklen/hlen
' Ti = F(Password, Salt, Iterations, i)
' The function F is the xor (^) of c iterations of chained PRFs. The first iteration of PRF uses 
' Password as the PRF key and Salt concatenated to i encoded as a big-endian 32-bit integer. (Note that i is a 1-based index.) 
' Subsequent iterations of PRF use Password as the PRF key and the output of the previous PRF computation as the salt:
'
' F(Password, Salt, Iterations, i) = U1 ^ U2 ^ ... ^ Uc
' where:
'
' U1 = PRF(Password, Salt || INT_msb(i))
' U2 = PRF(Password, U1)
' ...
' Uc = PRF(Password, Uc-1)
' For example, WPA2 uses:
'
' DK = PBKDF2(HMAC−SHA1, passphrase, ssid, 4096, 256)
'
' 1) Based on the above description firstly we need to create blocks of size hLen
' Define / get hLen (size in bytes) and do
' no of blocks = (desired length in bytes (IN_PARAM) + hLen-1) / hlen 
' 
' 2) allocate output with
'   outputBytes = no of blocks * hLen 
'
' 3) Password(IN_PARAM) key should be of exact lenght of block. add padding to password if less than block length, 
' Hash password if it is longer than the block length                 
'
' 4) iterate through each block (check step 1 - no. of blocks)
'{
'   5) Get the big endian for the calculation of frist U-iteration : U1
'   6) Calculate first iterations U1 =  PRF(Password, Salt || INT_msb(i))
'   7) run hashfunctions for the no. of desired interations (IN_PARAM) : i= 2 to no. of desired interations 
'   {   
'       8) Calculate Hash function for Ui +  update temp values for next iterations
'       9) Do XOR with output (all should be 1s as XOR will overrite values otherwise) and Ui
'   }
'   10) update the offsets and other variables to point to the next block 
'}
'
'11) Copy output to the result and return the result
'

function AkaMA_PBKDF2(password as object, salt as object, iterations as integer, desiredBytes as integer) as string
    hLenInBytes         =   20
    blockSizeInBytes    =   64
    resultStartOffset   =   0
    
    'Step-1 calculate no of blocks
    noOfBlocks = (desiredBytes + hLenInBytes-1) / hLenInBytes
    
    'Step-2 create output to hold the result
    resultBlock = CreateObject("roByteArray")
    
    'Step-3 Password hash or paddding
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(password)
    if ba.count() > blockSizeInBytes
        digest = CreateObject("roEVPDigest")
        digest.Setup("sha1")
        result = digest.Process(ba)
        ba = result
        digest = invalid
    endif
    
    'key = ba
    
    'Step-4 run loop for all blocks
    for block=1 to noOfBlocks
        inblock = CreateObject("roByteArray")
        inblock.FromAsciiString(salt)
        saltLen = inblock.count()'len(salt)
        
        'Step-5 Get the big endian for the calculation of frist U-iteration : U1
        inblock[saltLen + 0] = AkaMA_RightShift(block, 24)        
        inblock[saltLen + 1] = AkaMA_RightShift(block, 16)
        inblock[saltLen + 2] = AkaMA_RightShift(block, 8)
        inblock[saltLen + 3] = block
         
        'step-6 Calculate first iterations U1 =  PRF(Password, Salt || INT_msb(i))        
        outBlock = CreateObject("roByteArray")
        outBlock = AkaMA_PBKDF2_F(ba, inblock)           
        resultBlock.Append(outBlock)
        
        'Step-7 run hashfunctions for the no. of desired interations (IN_PARAM) : i= 2 to no. of desired interations
        for iter=2 to iterations
            tempBlock = inblock
            inblock = outBlock
            outBlock = tempBlock
            outBlock = AkaMA_PBKDF2_F(ba, inblock)   'Step-8 Calculate Hash function for Ui +  update temp values for next iterations
            'Step-9 Do XOR with output (all should be 1s as XOR will overrite values otherwise) and Ui
            for b=0 to hLenInBytes-1
                'print "resultBlock[] = ";resultBlock[resultStartOffset+b];" and outblock[] = ";outBlock[b]
                resultBlock[resultStartOffset+b] = AkaMA_XOR(resultBlock[resultStartOffset+b], outBlock[b]) ' working code
                
            end for
        end for
        'Step-10: update the offsets and other variables to point to the next block
        'print"resultBlock="; resultBlock;"resultStartOffset = ";resultStartOffset
        resultStartOffset = resultStartOffset + hLenInBytes
        inblock = invalid
        outBlock = invalid
    end for
    
    'Step-11:Copy output to the result and return the result
    finalHash = LCase(resultBlock.ToHexString())
    'print "Final hash string= "finalHash.left(desiredBytes*2)
    
    ba = invalid
    resultBlock = invalid
    return finalHash.left(desiredBytes*2)
end function


'Function       :   AkaMA_PBKDF2_F
'Params         :   None 
'Return         :    
'Description    :   A function which calculates hash for individual block. refer to F(Password, Salt, Iterations, i) 
' This function uses HMAC for hashing. We need has key(password) and salt (with index for the first iteration) 
function AkaMA_PBKDF2_F(inKey as object, iBlock as object) as object
    innerHmac = CreateObject("roHMAC")
    ba = CreateObject("roByteArray")
    ba = inKey
    result = CreateObject("roByteArray")
    if innerHmac.setup("sha1", ba) = 0 
        innerHmac.update(iBlock)
        result = innerHmac.final()
    end if    
    ba = invalid
    innerHmac = invalid
    return result
end function

'Function       :   AkaMA_XOR
'Params         :   
'Return         :   returns xor value for an integer 
'Description    :   Do and operation in xorLhs and or operation in xorRhs. 
'                   do and operation on xorLhs, xorRhs and return the result
function AkaMA_XOR(lhs as object, rhs as object) as object
'if lhs <> invalid and rhs <> invalid
    xorLhs = (lhs and not rhs)
    xorRhs =  (not lhs and rhs)
    return (xorLhs or xorRhs)
'endif
'return invalid   
end function

'Function       :   AkaMA_LeftShift
'Params         :   
'Return         :   returns xor value for an integer 
'Description    :   Do and operation in xorLhs and or operation in xorRhs. 
'                   do and operation on xorLhs, xorRhs and return the result
function AkaMA_LeftShift(num as integer, noOfShifts as integer) as integer
    totalPower = 0
    for index=0 to noOfShifts
        totalPower = totalPower + (2^index)
    end for
    return num*totalPower
end function

'Function       :   AkaMA_RightShift
'Params         :   
'Return         :   returns xor value for an integer 
'Description    :   Do and operation in xorLhs and or operation in xorRhs. 
'                   do and operation on xorLhs, xorRhs and return the result
function AkaMA_RightShift(num as integer, noOfShifts as integer) as integer
    totalPower = 0
    for index=0 to noOfShifts
        totalPower = totalPower + (2^index)
    end for
    return num/totalPower
end function