      **********************************************************************************************
      *
      *  NAME:  TRUTHTOOL
      *  TYPE:  SQL/RPGLE MODULE
      *  DESC:  TRUTH MATRIX TOOLS
      *
      **********************************************************************************************

       ctl-opt
         nomain
         option(*srcstmt);                                                   // control spec

       dcl-ds pgmsts psds qualified;                                         // program status d/s
         pgmnam *proc;                                                       // program name
         pgmlib char(10) pos(81);                                            // program library
         jobnam char(10) pos(244);                                           // job name
         usrprf char(10) pos(254);                                           // orig user profile
         jobnum char(6)  pos(264);                                           // job number
         curusr char(10) pos(358);                                           // curr user profile
       end-ds;                                                               // program status d/s

       /copy qcpysrc,truthtool                                               // prototypes & storage

      **********************************************************************************************

       dcl-proc isTrue export;                                               // is condition true

       dcl-pi isTrue ind;                                                    // is condition true
         CondName like(MtrxHeadX.CondName) const;                            // condition name
         BankCode like(MtrxDetlX.BankCode) const options(*nopass);           // bank code
         DebtType like(MtrxDetlX.DebtType) const options(*nopass);           // debt type
         State    like(MtrxDetlX.State)    const options(*nopass);           // state abbreviation
         AreaCode like(MtrxDetlX.AreaCode) const options(*nopass);           // phone area code
         Exchange like(MtrxDetlX.Exchange) const options(*nopass);           // phone exchange
         Gender   like(MtrxDetlX.Gender)   const options(*nopass);           // gender code
         Marital  like(MtrxDetlX.Marital)  const options(*nopass);           // marital status
         Age      like(MtrxDetlX.AgeFrom)  const options(*nopass);           // attained age
       end-pi;                                                               // is condition true

       dcl-s HeaderIDx   like(MtrxHeadX.HeaderID);                           // header unique ID
       dcl-s ProgramX    like(MtrxHeadX.Program);                            // eligible program
       dcl-s BankCodeX   like(MtrxDetlX.BankCode);                           // bank code
       dcl-s DebtTypeX   like(MtrxDetlX.DebtType);                           // debt type
       dcl-s StateX      like(MtrxDetlX.State);                              // state abbreviation
       dcl-s AreaCodeX   like(MtrxDetlX.AreaCode);                           // phone area code
       dcl-s ExchangeX   like(MtrxDetlX.Exchange);                           // phone exchange
       dcl-s GenderX     like(MtrxDetlX.Gender);                             // gender code
       dcl-s MaritalX    like(MtrxDetlX.Marital);                            // marital status
       dcl-s AgeX        like(MtrxDetlX.AgeFrom);                            // attained age
       dcl-s EnabledX    like(MtrxDetlX.Enabled);                            // enabled (Y/N)
       dcl-s EffectiveX  like(MtrxDetlX.Effective);                          // effective date
       dcl-s ExpirationX like(MtrxDetlX.Expiration);                         // expiration date
       dcl-s CountX      like(MtrxDetlX.DetailID);                           // count of matches

       if %parms >= 2;                                                       // if bank code passed
         BankCodeX = BankCode;                                               // bank code argument
       endif;                                                                // if bank code passed

       if %parms >= 3;                                                       // if debt type passed
         DebtTypeX = DebtType;                                               // debt type argument
       endif;                                                                // if debt type passed

       if %parms >= 4;                                                       // if state code
         StateX = State;                                                     // state code argument
       endif;                                                                // if state code

       if %parms >= 5;                                                       // if phone area code
         AreaCodeX = AreaCode;                                               // area code argument
       endif;                                                                // if phone area code

       if %parms >= 6;                                                       // if phone exchange
         ExchangeX = Exchange;                                               // exchange argument
       endif;                                                                // if phone exchange

       if %parms >= 7;                                                       // if gender
         GenderX = Gender;                                                   // gender argument
       endif;                                                                // if gender

       if %parms >= 8;                                                       // if marital status
         MaritalX = Marital;                                                 // marital sts argument
       endif;                                                                // if marital status

       if %parms >= 9;                                                       // if attained age
         AgeX = Age;                                                         // age argument
       endif;                                                                // if attained age

       // First, determine if condition header is false, and return if it is.
       //   An invalid condition name is an automatic false.

       exec sql
         select  HeaderID,   Enabled,   Effective,   Expiration,   Program
           into :HeaderIDx, :EnabledX, :EffectiveX, :ExpirationX, :ProgramX
             from MtrxHead
               where CondName = :CondName
                 and CURRENT_DATE between Effective and Expiration
                 and :ProgramX = ' ' or
                     :ProgramX in (select PROGRAM_NAME
                                     from table (STACK_INFO('*')));          // get condition header

       if sqlcode  <> 0
       or %date()   < EffectiveX
       or %date()   > ExpirationX
       or EnabledX <> 'Y';                                                   // if invalid/inactive
         return *off;                                                        // condition is false
       endif;                                                                // if invalid/inactive

       // Second, if there are no criteria, then the condition is true.

       exec sql
         select count(*) into :CountX from MtrxDetl
           where HeaderID = :HeaderIDx;                                     // how many criteria

       if CountX = 0;                                                       // if no criteria
         return *on;                                                        // condition is true
       endif;                                                               // if no criteria

       // Third, if any of the critera match the arguments, including
       //   wild cards, then the condition is true.  Otherwise it's false.

       exec sql
         select count(*) into :CountX from MtrxDetl
           where HeaderID = :HeaderIDx
             and Enabled = 'Y'
             and CURRENT_DATE between Effective and Expiration
             and (:BankCodeX = ' ' or BankCode in (' ', :BankCodeX))
             and (:DebtTypeX = ' ' or DebtType in (' ', :DebtTypeX))
             and (:StateX    = ' ' or State    in (' ', :StateX))
             and (:AreaCodeX = 0   or AreaCode in (0,   :AreaCodeX))
             and (:ExchangeX = 0   or Exchange in (0,   :ExchangeX))
             and (:GenderX   = ' ' or Gender   in (' ', :GenderX))
             and (:MaritalX  = ' ' or Marital  in (' ', :MaritalX))
             and (:AgeX      = 0   or AgeFrom  = 0 and AgeThru  = 0
                                   or AgeFrom <= :AgeX and AgeThru >= :AgeX)
             and (Program = ' '
                    or Program in (select PROGRAM_NAME
                                     from table(STACK_INFO('*'))));          // look for matches

       return (CountX > 0);                                                  // true if matches

       end-proc;                                                             // is condition true

