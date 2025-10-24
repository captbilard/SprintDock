import { Injectable } from '@nestjs/common';
import { UserDTO } from './dto/user.dto';
import { User } from '../../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import * as argon2 from 'argon2';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async createUser(payload: UserDTO): Promise<object> {
    try {
      const passwordHash = await argon2.hash(payload.password);
      const user = (await this.prisma.user.create({
        data: {
          firstName: payload.firstName,
          lastName: payload.lastName,
          email: payload.email,
          passwordHash,
        },
      })) as User;
      const token = this.jwtService.sign({ userId: user.id });
      return { token };
    } catch (error) {
      throw new Error(
        `There was an error creating the user: ${error?.message}`,
      );
    }
  }
}
