package cn222nd_lab1;

import java.util.Scanner;

public class BMI {

	public static void main(String[] args) {
		Scanner scan = new Scanner(System.in);
		System.out.print("Längd i meter: ");
		double length = scan.nextDouble();
		System.out.print("Vikt i kg: ");
		double weight = scan.nextDouble();
		
		double BMI = weight / Math.pow(length, 2) ;
		long BMI2 = Math.round(BMI); 
			// Beräkning samt avrundning
		System.out.print("BMI: " + BMI2);
		
		

	}

}
