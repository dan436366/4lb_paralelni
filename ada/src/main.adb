with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Numerics.Float_Random;

procedure Philosophers_Main is

   package Float_Random_Pkg renames Ada.Numerics.Float_Random;
   Generator : Float_Random_Pkg.Generator;

   protected type Hungry_Check_Fork is
      entry Get;
      function Try_Get return Boolean;
      procedure Put;
   private
      Available : Boolean := True;
   end Hungry_Check_Fork;

   protected body Hungry_Check_Fork is
      entry Get when Available is
      begin
         Available := False;
      end Get;

      function Try_Get return Boolean is
      begin
         return Available;
      end Try_Get;

      procedure Put is
      begin
         Available := True;
      end Put;
   end Hungry_Check_Fork;

   type Hungry_Check_Fork_Array is array (0..4) of Hungry_Check_Fork;
   type Boolean_Array is array (0..4) of Boolean;

   protected type Hungry_Check_Table is
      entry Try_To_Eat (Philosopher_Id : Integer; Success : out Boolean);
      procedure Finish_Eating (Philosopher_Id : Integer);
   private
      Forks : Hungry_Check_Fork_Array;
      Has_Left_Fork : Boolean_Array := (others => False);
      Has_Right_Fork : Boolean_Array := (others => False);
      Hungry_Count : Integer := 0;
   end Hungry_Check_Table;

   protected body Hungry_Check_Table is
      entry Try_To_Eat (Philosopher_Id : Integer; Success : out Boolean) when True is
         Left_Fork : Integer := (Philosopher_Id + 1) mod 5;
      begin
         Success := False;

         if Hungry_Count >= 4 then
            return;
         end if;

         if Forks(Philosopher_Id).Try_Get then
            select
               Forks(Philosopher_Id).Get;
               Has_Right_Fork(Philosopher_Id) := True;
               Hungry_Count := Hungry_Count + 1;
               Put_Line("Philosopher" & Integer'Image(Philosopher_Id) &
                        " picked up right fork" & Integer'Image(Philosopher_Id) &
                        " (hungry count:" & Integer'Image(Hungry_Count) & ")");

               if Forks(Left_Fork).Try_Get then
                  select
                     Forks(Left_Fork).Get;
                     Has_Left_Fork(Philosopher_Id) := True;
                     Put_Line("Philosopher" & Integer'Image(Philosopher_Id) &
                              " picked up left fork" & Integer'Image(Left_Fork));
                     Success := True;
                     return;
                  else
                     null;
                  end select;
               end if;

               Forks(Philosopher_Id).Put;
               Has_Right_Fork(Philosopher_Id) := False;
               Hungry_Count := Hungry_Count - 1;
            else
               null;
            end select;
         end if;
      end Try_To_Eat;

      procedure Finish_Eating (Philosopher_Id : Integer) is
         Left_Fork : Integer := (Philosopher_Id + 1) mod 5;
      begin
         if Has_Left_Fork(Philosopher_Id) then
            Forks(Left_Fork).Put;
            Has_Left_Fork(Philosopher_Id) := False;
            Put_Line("Philosopher" & Integer'Image(Philosopher_Id) &
                     " put down left fork" & Integer'Image(Left_Fork));
         end if;

         if Has_Right_Fork(Philosopher_Id) then
            Forks(Philosopher_Id).Put;
            Has_Right_Fork(Philosopher_Id) := False;
            Hungry_Count := Hungry_Count - 1;
            Put_Line("Philosopher" & Integer'Image(Philosopher_Id) &
                     " put down right fork" & Integer'Image(Philosopher_Id) &
                     " (hungry count:" & Integer'Image(Hungry_Count) & ")");
         end if;
      end Finish_Eating;
   end Hungry_Check_Table;

   task type Hungry_Check_Philosopher (Id : Integer; Table : access Hungry_Check_Table);

   task body Hungry_Check_Philosopher is
      Success : Boolean;
   begin
      for I in 1..5 loop
         Put_Line("Philosopher" & Integer'Image(Id) & " is thinking" & Integer'Image(I) & " times");
         delay Duration(Float_Random_Pkg.Random(Generator) * 0.1);

         loop
            Table.Try_To_Eat(Id, Success);
            exit when Success;
            Put_Line("Philosopher" & Integer'Image(Id) & " couldn't eat (too many hungry), waiting...");
            delay 0.05;
         end loop;

         Put_Line("Philosopher" & Integer'Image(Id) & " is eating" & Integer'Image(I) & " times");
         delay Duration(Float_Random_Pkg.Random(Generator) * 0.1);

         Table.Finish_Eating(Id);
      end loop;
      Put_Line("Philosopher" & Integer'Image(Id) & " finished eating");
   end Hungry_Check_Philosopher;

   procedure Run_Hungry_Check_Solution is
   begin
      Put_Line("");
      Put_Line("=== Running hungry check solution (15 times) ===");

      for Run in 1..15 loop
         Put_Line("");
         Put_Line("--- Run #" & Integer'Image(Run) & " ---");

         declare
            Table : aliased Hungry_Check_Table;
            type Phil_Access is access Hungry_Check_Philosopher;
            Philosophers : array (0..4) of Phil_Access;
         begin
            for I in 0..4 loop
               Philosophers(I) := new Hungry_Check_Philosopher(I, Table'Access);
            end loop;
         end;

         Put_Line("Run #" & Integer'Image(Run) & " completed successfully");
         delay 0.1;
      end loop;
      Put_Line("");
      Put_Line("=== Hungry check solution: all 15 runs completed ===");
   end Run_Hungry_Check_Solution;

begin
   Float_Random_Pkg.Reset(Generator);
   Run_Hungry_Check_Solution;
end Philosophers_Main;
