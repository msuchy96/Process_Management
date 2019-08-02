public class RandomUtility {
    
    public final static Integer STRING_LENGTH = 3;

    public static Integer createRandomNumber() {
        return Math.Round(Math.Random() * ((Math.pow(10,STRING_LENGTH) - 1)-Math.pow(10,STRING_LENGTH -1)) + Math.pow(10,STRING_LENGTH -1));
    }

    //method to return random value between 2 numbers
    public static Integer generateRandomFromRange(integer startNum, integer endNum){
        Integer returnValue;
        Integer randomNumber = Integer.valueof((math.random() * 10));
        boolean addSubFlag= math.mod(randomNumber,2) == 0 ? true : false;
        
        integer diffInRange = endNum-startNum;
        //Now find random number staring from 0 to diffInRange
        Integer randomNum = Math.mod(Math.round(Math.random()*diffInRange+1),diffInRange);
        return diffInRange > 1 ? startNum + randomNum : startNum;
    }
}